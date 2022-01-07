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
import "./enums/EquipmentSlot.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/structs/EnumerableSet.sol";

contract Warden {
    
    using EnumerableSet for EnumerableSet.AddressSet;

    event GameTick(uint256 indexed tickNumber, uint256 indexed tickBlockHeight, uint advancableArenas);
    
    World public immutable WORLD;

    uint private tickBlockHeight;

    uint public tickNumber;
    
    uint private seed;
    uint private itemNonce; //Incremented each time a unique Item is created.  Else all items in a given tick would be identical
    uint private arenaNonce;

    EnumerableSet.AddressSet private arenas;

    mapping(Item => bytes32) private items; //A hash of all important item attributes, anti-cheat and model validation mechanism



    modifier isZima() {
        require(msg.sender == WORLD.zima(), "Caller not Zima!");
        _;
    }
    
    modifier isNextTick() {
        //Checks current block height against previous tick's height + number of blocks per tick defined in World contract.  
        uint nextTickHeight = tickBlockHeight + WORLD.blocksPerTick();
        require(block.number >= nextTickHeight, "Not Ready!");
        _;
    }

    modifier isArena() {
        //Checks arenaStatus of caller to ensure they're an active Arena (status == 1)
        Arena arena = Arena(msg.sender);
        require(arenas.contains(msg.sender), "Caller Not Arena!");
        _;
    }
   
    //To be Called by World Contract
    constructor(uint _seed) {
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

    function tick(uint _seed) external isZima isNextTick {
        tickBlockHeight = block.number;
        seed = _seed;
        tickNumber++;
        handleArenas();
        emit GameTick(tickNumber, tickBlockHeight, arenas.length());
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
            arena.open();
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
    //TODO Update this to use isArena modifier once done testing
    function spawnItem(EquipmentSlot _slot, ItemTier _tier, uint _seed, address _owner) public isZima returns (address) {
        Item newItem = new Item(_slot, _tier, _seed, _owner);
        return address(newItem);
    }
}