pragma solidity >=0.7.0 <0.9.0;

//SPDX-License-Identifier: UNLICENSED
import "./World.sol";
import "./Player.sol";
import "./Boss.sol";
import "./Item.sol";
import "./enums/Status.sol";
import "./enums/Objective.sol";
import "./enums/EntityType.sol";
import "./structs/PlayerState.sol";
import "./structs/Tile.sol";






contract Arena {

    World constant private WORLD = World(0x234234234342234);

    address public owner;

    uint public gridRows;

    uint public gridColumns;

    Boss public boss;

    Player[WORLD.arenaMaxPlayers] players;

    mapping(Player => PlayerState) playerState;

    uint private deadPlayerCount; //Incremented whenever a player dies in arena, used to check remaining players

    Tile[] private grid; //Not all tiles will be visited so dynamically-sized should be better here?

    Status public status;

    uint public startTick;

    uint public maxTicks;

    uint private seed;


    event StatusChanged(Status oldStatus, Status newStatus, StatusChangeDetail detail);
    event PlayerAdvanced(address indexed Player, Objective objective, uint oldTile, uint newTile);
    event BossDefeated(address indexed boss);


    modifier isWarden() {
        require(msg.sender == WORLD.warden, "Caller is Not Current Warden!");
        _;
    }

    modifier playerCanJoin() {
        require(status == Status.Open, "Arena is Not Open!");
        _;
    }

    modifier canOpen() {
        require(status == Status.New, "Only New Arenas can be Opened!");
    }


    constructor(uint _seed, uint _startTick, Boss _boss) {
        maxTicks = WORLD.arenaMaxTicks;
        seed = _seed;
        startTick = _startTick;
        boss = _boss;
    }

    function setStatus(Status _newStatus, StatusChangeDetail _detail) internal {
        emit StatusChanged(status, _newStatus, _detail);
        status = _newStatus;
    }
    
    function handleDeadEntity(uint _tile, uint _tileIndex) internal {
        //All Dead Entities should immediately be moved to the Void
        _entity.moveToVoid();
        if (_entity.eType == EntityType.Player) {
            deadPlayerCount++;
            return; //TODO Add something here to restore their health 
        } else if (_entity.eType == EntityType.Boss) {
            emit BossDefeated(boss);
        } else {
            revert("Failed to Handle Dead Entity - Entity Type Should Never Die!");
        }
    }

    function handleCombat(uint _tile, uint _tileIndex, TileEntity _tEntity) internal {
        //This can be negative
        int netDamage = grid[_tile].damage - _tEntity.getDamageReduction();
        if (netDamage < 0) {
            return;
        }
        bool damageWasFatal = tEntity.entity.damage(grid[_tile].damage);
        if (damageWasFatal) {
            handleDeadEntity(_tile, _tileIndex);
        }
        return;
    }

    function spawnEntity(Entity _entity) internal {
        uint startTile = (seed * players.length) % (gridColumns * gridRows);
        _entity.moveTo(startTile);
    }


    function join(Player _player) external playerCanJoin {
        spawnEntity(_player);
        players.push(_player);
    }


    function advancePlayer(Player _player) internal {
        uint oldTile = _player.tile;
        if (_player.objective == Objective.Boss) {
            _player.moveTowards(boss.tile);
        } else if (_player.objective == Objective.Wait) {
            return; //TODO Do something here
        } else {
            revert("Failed to Advance Player - Unknown Objective");
        }
        uint newTile = _player.tile;
        //emit PlayerAdvanced(_player, _player.objective, oldTile, newTile);
    }


    function updateStatus() internal {
        if (canOpen()) {
            setStatus(Status.Open);
        } else if (canStart()) {
            setStatus(Status.Active);
        } else if(canComplete()) {
            setStatus(Status.Complete);
        }
    }

    function handleStatus() internal {
        if (status == Status.Open) {
            open();
        } else if (status == Status.Active) {
            advance();
        } else if (status == Status.Complete) {
            warden.closeArena();
        }
    }

    function canOpen() internal view returns (bool) {
        if (status == Status.New) {
            return true;
        }
        return false;
    }

    function canStart() internal view returns (bool) {
        if (status == Status.Open) {
            if ((startTick - 1) > warden.tick) {
                return true;
            }
        }
        return false;
    }

    function canComplete() internal view returns (bool) {
        if (status == Status.Active) {
            if (players.length - deadPlayerCount < 2) {
                return true;
            } else if (warden.tick > (startTick + maxTicks)) {
                return true;
            }
        }
        return false;
    }


    //Check for arena-ending conditions, update status if found
    function arenaIsComplete() internal view returns (bool) {
        if (players.length - deadPlayerCount < 2) {
            return true;
        } else if (warden.tick > (startTick + maxTicks)) {
            return true;
        }
        return false;
        }
    }

    function arenaIsActive() internal view returns (bool) {
        if (status == Status.Active) {
            return true;
        } else {
            return false;
        }
    }


    //Don't Update Tile 0 (Home / Death Tile)
    function advance() external isWarden {
        for (uint tile = 1; tile < (grid.length - 1); tile++) {
            bool tileWasUpdated = updateTile(tile);
            if (tileWasUpdated) {
                executeTile(tile);
            }
        }
    }

    function open() external isWarden canOpen {
        spawnEntity(boss);
    }

    function close() external isWarden {
        
        setStatus(Status.Closed);
    }

    function tick() external isWarden {
        updateStatus();
        handleStatus();
    }


    function updateTile(uint _tile) internal returns (bool) {
        //Ignore blank tiles
        uint activeEntities;
        uint damage;
        if (!grid[tile].entities.length) {
            return false; //Allows us to skip execution of tiles with no data
        } else {
            for (int i = 0; i < grid[tile].entities.length; i++) {
                TileEntity tEntity = grid[tile].entities[i];
                //Ignore entities which have already been moved
                if (tEntity.hasMoved) {
                    continue; //Tile contains a single entity that has moved elsewhere
                //Entity Moved after last grid update
                } else if (_tile != tEntity.entity.tile) {
                    grid[_tile].entities[i].hasMoved = true;
                //Entity Died after last grid update
                } else if (!tEntity.entity.isAlive()) {
                    handleDeadEntity(_tile, i);
                } else {
                    activeEntities++;
                    damage += tEntity.entity.getDamageOutput();
                }
            }
        }
        grid[_tile].count = activeEntities;
        grid[_tile].damage = damage;
        return true;
    }

    function executeTile(uint _tile) internal {
        bool entityCanAdvance;
        //Ignore tiles with no Active Entities
        if (!grid[_tile].activeEntities) {
            return;
        }
        if (grid[_tile].activeEntities == 1) {
            entityCanAdvance = true;
        }

        for (uint i = 0; i < grid[_tile].entities.length; i++) {
            TileEntity tEntity = grid[tile].entities[i];
            //Ignore  entities which have already been moved
            if (tEntity.hasMoved) {
                continue;
            } else if (entityCanAdvance) {
                continue; //Only one Active Entity on this tile, allow it to advance
            } else {
                handleCombat(_tile, i, tEntity);
            }
        }
    }
}