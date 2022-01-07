pragma solidity >=0.7.0 <0.9.0;

//SPDX-License-Identifier: UNLICENSED
import "./World.sol";
import "./Player.sol";
import "./Boss.sol";
import "./Item.sol";
import "./enums/Status.sol";
import "./enums/Objective.sol";
import "./enums/EntityType.sol";
import "./enums/ItemTier.sol";
import "./structs/PlayerState.sol";
import "./structs/Tile.sol";






contract Arena {

    World constant private WORLD = World(0x992DA8eC2af8ec58E89E3293Fb3aaC8ebD7602B8);

    ItemTier public tier;

    address public owner;

    uint public gridRows;

    uint public gridColumns;

    Boss public boss;

    Player[] public players;

    mapping(Player => PlayerState) public playerState;

    uint private deadPlayerCount; //Incremented whenever a player dies in arena, used to check remaining players

    Tile[] private grid; //Not all tiles will be visited so dynamically-sized should be better here?

    Status public status;

    uint public startTick;

    uint public maxTicks;

    uint private seed;


    event StatusChanged(Status oldStatus, Status newStatus);
    event PlayerAdvanced(address indexed Player, Objective objective, uint oldTile, uint newTile);
    event BossDefeated(Boss indexed boss);


    modifier isWarden() {
        require(msg.sender == WORLD.warden(), "Caller is Not Current Warden!");
        _;
    }

    modifier playerCanJoin() {
        require(status == Status.Open, "Arena is Not Open!");
        _;
    }

    modifier isNew() {
        require(status == Status.New, "Arena is Not New!");
        _;
    }


    constructor(uint _seed, uint _startTick, ItemTier _tier) {
        maxTicks = WORLD.arenaMaxTicks();
        seed = _seed;
        startTick = _startTick;
        tier = _tier;
    }

    function setStatus(Status _newStatus) internal {
        emit StatusChanged(status, _newStatus);
        status = _newStatus;
    }
    
    function handleDeadEntity(Entity _entity) internal {
        //All Dead Entities should immediately be moved to the Void
        
        _entity.moveToVoid();
        EntityType _eType = _entity.eType();
        if (_eType == EntityType.Player) {
            deadPlayerCount++;
            return; //TODO Add something here to restore their health 
        } else if (_eType == EntityType.Boss) {
            emit BossDefeated(boss);
        } else {
            revert("Failed to Handle Dead Entity - Entity Type Should Never Die!");
        }
    }

    function handleCombat(uint _tile, TileEntity memory _tEntity) internal {
        //Total Tile damage less than damage reduction, entity took no damage
        if ((grid[_tile].damage - (_tEntity.entity.getDamageOutput() + _tEntity.entity.getDamageReduction())) < 0) {
            return;
        }
        bool damageWasFatal = _tEntity.entity.damage(grid[_tile].damage);
        if (damageWasFatal) {
            handleDeadEntity(_tEntity.entity);
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
        if (_player.objective() == Objective.Boss) {
            _player.moveTowards(boss.tile(), gridRows);
        } else if (_player.objective() == Objective.Camp) {
            return; //TODO Do something here
        } else {
            revert("Failed to Advance Player - Unknown Objective");
        }
    }


    function updateStatus(uint _tickNumber) internal {
        if (canStart(_tickNumber)) {
            setStatus(Status.Active);
        } else if(canComplete(_tickNumber)) {
            setStatus(Status.Complete);
        }
    }

    function handleStatus() internal {
        if (status == Status.Active) {
            advance();
        }
    }


    function canStart(uint _tickNumber) internal view returns (bool) {
        if (status == Status.Open) {
            if ((startTick - 1) > _tickNumber) {
                return true;
            }
        }
        return false;
    }

    function canComplete(uint _tickNumber) internal view returns (bool) {
        if (status == Status.Active) {
            if (players.length - deadPlayerCount < 2) {
                return true;
            } else if (_tickNumber > (startTick + maxTicks)) {
                return true;
            }
        }
        return false;
    }

    function arenaIsActive() internal view returns (bool) {
        if (status == Status.Active) {
            return true;
        } else {
            return false;
        }
    }


    //Don't Update Tile 0 (Home / Death Tile)
    function advance() internal {
        for (uint i = 1; i < (grid.length - 1); i++) {
            bool tileWasUpdated = updateTile(i);
            if (tileWasUpdated) {
                executeTile(i);
            }
        }
    }

    function open() external isWarden isNew {
        //TODO Finish Bossery and update func to spwan boss
        setStatus(Status.Open);
    }

    function close() external isWarden {
        
        setStatus(Status.Closed);
    }

    function tick(uint _tickNumber) external isWarden {
        updateStatus(_tickNumber);
        handleStatus();
    }


    function updateTile(uint _tile) internal returns (bool) {
        //Ignore blank tiles
        uint activeEntities;
        uint damage;
        if (grid[_tile].entities.length == 0) {
            return false; //Allows us to skip execution of tiles with no data
        } else {
            for (uint i = 0; i < grid[_tile].entities.length; i++) {
                //Ignore entities which have already been moved
                if (grid[_tile].entities[i].hasMoved) {
                    continue; //Tile contains a single entity that has moved elsewhere
                //Entity Moved after last grid update
                } else if (_tile != grid[_tile].entities[i].entity.tile()) {
                    grid[_tile].entities[i].hasMoved = true;
                //Entity Died after last grid update
                } else if (!grid[_tile].entities[i].entity.isAlive()) {
                    handleDeadEntity(grid[_tile].entities[i].entity);
                } else {
                    activeEntities++;
                    damage += grid[_tile].entities[i].entity.getDamageOutput();
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
        if (grid[_tile].count == 0) {
            return;
        }
        if (grid[_tile].count == 1) {
            entityCanAdvance = true;
        }

        for (uint i = 0; i < grid[_tile].entities.length; i++) {
            //Ignore  entities which have already been moved
            if (grid[_tile].entities[i].hasMoved) {
                continue;
            } else if (entityCanAdvance) {
                continue; //Only one Active Entity on this tile, allow it to advance
            } else {
                handleCombat(_tile, grid[_tile].entities[i]);
            }
        }
    }

    function playerCount() public view returns (uint) {
        return players.length;
    }

    function playerRewardCount(Player _player) public view returns (uint) {
        return playerState[_player].itemRewards.length;
    }

    function playerRewardItem(Player _player, uint _index) public view returns (Item) {
        require(this.playerRewardCount(_player) > _index, "Index is Invalid");
        return playerState[_player].itemRewards[_index];
    }
}