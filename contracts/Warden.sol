pragma solidity >=0.7.0 <0.9.0;

//SPDX-License-Identifier: UNLICENSED

import "./World.sol";
import "./Arena.sol";
import "./Player.sol";
import "./Boss.sol";
import "./Vault.sol";
import "./enums/Status.sol";
import "./enums/ItemTier.sol";
import "./structs/PlayerState.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/structs/EnumerableSet.sol";

contract Warden {
    
    using EnumerableSet for EnumerableSet.AddressSet;

    event GameTick(uint256 indexed tickNumber, uint256 indexed tickBlockHeight, uint advancableArenas);
    
    address public worldAddress;
    World public WORLD = World(worldAddress);
    
    address public owner;

    uint256 public tickBlockHeight;

    uint256 public tickNumber;
    
    uint256 private seed;
    uint256 private itemNonce; //Incremented each time a unique Item is created.  Else all items in a given tick would be identical
    uint256 private arenaNonce;

    EnumerableSet.AddressSet private arenas;

   

    mapping(Arena => Status) private arenaStatus; //A mapping of Arena addresses to hashes of important arena attributes, anti-cheat and model validation mechanism

    mapping(Player => bytes32) private players; //A hash of all important player attributes, anti-cheat mechanism

    mapping(Item => bytes32) private items; //A hash of all important item attributes, anti-cheat and model validation mechanism



    modifier isOwner() {
        // If the first argument of 'require' evaluates to 'false', execution terminates and all
        // changes to the state and to Ether balances are reverted.
        // This used to consume all gas in old EVM versions, but not anymore.
        // It is often a good idea to use 'require' to check if functions are called correctly.
        // As a second argument, you can also provide an explanation about what went wrong.
        require(msg.sender == owner, "Caller is not owner");
        _;
    }
    
    modifier isNextTick() {
        //Checks current block height against previous tick's height + number of blocks per tick defined in World contract.  
        uint256 nextTickHeight = tickBlockHeight + WORLD.blocksPerTick();
        require(block.number >= nextTickHeight, "Not Ready to Advance Tick!");
        _;
    }

    modifier isActiveArena() {
        //Checks arenaStatus of caller to ensure they're an active Arena (status == 1)
        Arena arena = Arena(msg.sender);
        require(arena.status() == Status.Active, "Caller is Not an Active Arena!");
        _;
    }

    modifier isCompletedArena() {
        //Checks arenaStatus of caller to ensure they're a completed Arena, used for reward generation (status == 2)
        Arena arena = Arena(msg.sender);
        require(arena.status() == Status.Complete, "Caller is Not an Active Arena!");
        _;
    }

    modifier isCommonItem(ItemTier _tier) {
        require(_tier < ItemTier.Exotic, "Item Tier Must be Less than Exotic");
        _;
    }

    modifier isValidPlayer(Player _player) {
        bytes32 validHash = players[_player];
        require(validHash != 0, "Address is Not a Familiar Player!"); //Don't bother trying to calculate a new hash if the address isn't found
        _;
    }
   
    //To be Called by World Contract
    constructor(uint256 _seed) {
        owner = msg.sender;
        worldAddress = owner; //TODO Hard-Code World Address
        tickNumber = 1; //Increment our tick
        tickBlockHeight = block.number; //Set tickBlockHeight to current block
        seed = _seed;
    }

    function playerIsValid(Player _player) external view returns (bool isValid) {
        if (players[_player] == 0) {
            return isValid; //Player is Not Found in Mapping
        }
    }
    

    function getItemSeed() internal returns (uint) {
        itemNonce++;
        return seed ^ itemNonce;
    }

    function getArenaSeed() internal returns (uint){
        arenaNonce++;
        return seed ^ arenaNonce;
    }

    function grantItemReward(Player _player, ItemTier _tier) external isCompletedArena {
        Vault vault = Vault(WORLD.vault());
        Item rewardItem = vault.generateReward(_tier, seed);
        _player.addItemToInventory(rewardItem);

    }

    function closeArena() external isActiveArena {
        Arena _arena = Arena(msg.sender);
        if (_arena.status() != Status.Complete) {
            revert("Failed to Close Arena - Status is Not Complete");
        }
        for (uint i = 0; i < _arena.playerCount(); i++) {
            Player player = _arena.players(i);
            player.moveToVoid();
            for (uint j = 0; j < _arena.playerRewardCount(player); j++) {
                
                Item rewardItem = _arena.playerRewardItem(player, j);
                player.addItemToInventory(rewardItem);
            }
        }
        _arena.close();
    }

    function handleArena(address _arena) internal {
        Arena arena = Arena(_arena);
        Status arenaStatus = arena.status();
        if (arenaStatus == Status.Complete) {
            arena.close();
        } else if (arenaStatus == Status.Closed) {
            arenas.remove(_arena);
        } else {
            arena.tick(seed);
        }
    }

    function handleArenas(uint _seed) internal {
        for (uint i = 0; i < arenas.length(); i++){
            handleArena(arenas.at(i));
        }
    }

    function grantExperienceReward(Player _player, Skill _skill, uint256 _experience) external isCompletedArena {
        _player.receiveExperience(_skill, _experience);
    }

    function tick(uint256 _seed) external isOwner isNextTick {
        tickBlockHeight = block.number;
        seed = _seed;
        tickNumber++;
        handleArenas(_seed);
        emit GameTick(tickNumber, tickBlockHeight, arenas.length());
    }

    function createArena(Boss _boss) external {
        Arena _newArena = new Arena(getArenaSeed(), tickNumber + 1, _boss);
        arenas.add(address(_newArena));
    }

    function getArenas() external view isOwner returns (address[] memory) {
        return arenas.values();
    }
}