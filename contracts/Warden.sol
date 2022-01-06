pragma solidity >=0.7.0 <0.9.0;

//SPDX-License-Identifier: UNLICENSED

import "./World.sol";
import "./Arena.sol";
import "./Player.sol";
import "./Boss.sol";
import "./Vault.sol";
import "./Weapon.sol";
import "./enums/Status.sol";
import "./enums/ItemTier.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/structs/EnumerableSet.sol";

contract Warden {
    
    using EnumerableSet for EnumerableSet.AddressSet;

    event GameTick(uint256 indexed tickNumber, uint256 indexed tickBlockHeight, uint advancableArenas);
    
    World public immutable WORLD;

    uint private tickBlockHeight;

    uint256 public tickNumber;
    
    uint256 private seed;
    uint256 private itemNonce; //Incremented each time a unique Item is created.  Else all items in a given tick would be identical
    uint256 private arenaNonce;

    EnumerableSet.AddressSet private arenas;

    mapping(Item => bytes32) private items; //A hash of all important item attributes, anti-cheat and model validation mechanism



    modifier isZima() {
        require(msg.sender == WORLD.zima(), "Caller is not Zima!");
        _;
    }
    
    modifier isNextTick() {
        //Checks current block height against previous tick's height + number of blocks per tick defined in World contract.  
        uint256 nextTickHeight = tickBlockHeight + WORLD.blocksPerTick();
        require(block.number >= nextTickHeight, "Not Ready to Advance Tick!");
        _;
    }

    modifier isArena() {
        //Checks arenaStatus of caller to ensure they're an active Arena (status == 1)
        Arena arena = Arena(msg.sender);
        require(arenas.contains(msg.sender), "Caller is Not an Arena!");
        _;
    }
   
    //To be Called by World Contract
    constructor(uint256 _seed) {
        WORLD = World(msg.sender);
        tickNumber = 1; //Increment our tick
        tickBlockHeight = block.number; //Set tickBlockHeight to current block
        seed = _seed;
    }
    

    function getItemSeed() internal returns (uint) {
        itemNonce++;
        return seed ^ itemNonce;
    }

    function getArenaSeed() internal returns (uint){
        arenaNonce++;
        return seed ^ arenaNonce;
    }

    function grantItemReward(Player _player, ItemTier _tier) external isArena {
        Vault vault = Vault(WORLD.vault());
        Item rewardItem = vault.generateReward(_tier, seed);
        _player.addItemToInventory(rewardItem);

    }
    
    function grantExperienceReward(Player _player, Skill _skill, uint256 _experience) external isArena {
        _player.receiveExperience(_skill, _experience);
    }

    function tick(uint256 _seed) external isZima isNextTick {
        tickBlockHeight = block.number;
        seed = _seed;
        tickNumber++;
        handleArenas();
        emit GameTick(tickNumber, tickBlockHeight, arenas.length());
    }

    function createBoss(Arena _arena) internal returns (Boss _newBoss) {
        _newBoss = new Boss(_arena.tier(), seed);
        address arenaAddress = address(_arena);
        Vault vault = Vault(WORLD.vault());
        for (uint i = 0; i < WORLD.inventorySlots(); i++){
            _newBoss.addItemToInventory(vault.generateReward(_arena.tier(), seed));
        }
        _newBoss.setArena(arenaAddress);
        if (_newBoss.arena() == arenaAddress) {
            return _newBoss;
        } else {
            revert("Failed to Create Boss - Arena Mismatch!");
        }
    }

    function createArena(ItemTier _tier) external returns (address _newArenaAddress) {
        Arena _newArena = new Arena(getArenaSeed(), tickNumber + 1, _tier);
        _newArenaAddress = address(_newArena);
        arenas.add(_newArenaAddress);
    }

    function getArenas() external view returns (address[] memory) {
        return arenas.values();
    }

    function createPlayer() external returns (address _newPlayerAddress) {
        Player _newPlayer = new Player(msg.sender);
        _newPlayerAddress = address(_newPlayer);
    }

    function handleArena(address _arena) internal {
        Arena arena = Arena(_arena);
        Status arenaStatus = arena.status();
        if (arenaStatus == Status.New) {
            Boss arenaBoss = createBoss(arena);
            arena.open(arenaBoss);
        } else if (arenaStatus == Status.Complete) {
            arena.close();
        } else if (arenaStatus == Status.Closed) {
            arenas.remove(_arena);
        } else {
            arena.tick(tickNumber);
        }
    }

    function handleArenas() internal {
        for (uint i = 0; i < arenas.length(); i++){
            handleArena(arenas.at(i));
        }
    }

    function spawnWeapon(ItemTier _tier, uint _seed) public isZima returns (address) {
        Weapon newWeapon = new Weapon(_tier, _seed, WORLD.zima()); //Hard-code all items to be owned by Zima
        return address(newWeapon);
    }
}