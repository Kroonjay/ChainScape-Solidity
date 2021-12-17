pragma solidity >=0.7.0 <0.9.0;

//SPDX-License-Identifier: UNLICENSED

import "./World.sol";
import "./Arena.sol";
import "./Player.sol";
import "./Boss.sol";
import "./enums/Status.sol";
import "./enums/ItemTier.sol";
import "./structs/PlayerState.sol";


contract Warden {
    
    event GameTick(uint256 indexed tickNumber, uint256 indexed tickBlockHeight, uint advancableArenas);
    
    address public worldAddress;
    World public WORLD = World(worldAddress);
    
    address public owner;

    uint256 public tickBlockHeight;

    uint256 public tickNumber;
    
    uint256 private seed;
    uint256 private itemNonce; //Incremented each time a unique Item is created.  Else all items in a given tick would be identical
    uint256 private arenaNonce;

    Arena[] private activeArenas;

   

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
        require(msg.sender.status == Status.Active, "Caller is Not an Active Arena!");
        _;
    }

    modifier isCompletedArena() {
        //Checks arenaStatus of caller to ensure they're a completed Arena, used for reward generation (status == 2)
        require(arenaStatus[msg.sender] == Status.Active, "Caller is Not an Active Arena!");
        _;
    }

    modifier isCommonItem(ItemTier _tier) {
        require(_tier < ItemTier.Exotic, "Item Tier Must be Less than Exotic");
        _;
    }

    modifier isValidPlayer(Player _player) {
        bytes32 validHash = players[_player];
        require(validHash != 0, "Address is Not a Familiar Player!"); //Don't bother trying to calculate a new hash if the address isn't found
        bytes32 playerHash = WORLD.hashPlayer(_player);
        require(validHash == playerHash, "Player Hash is Invalid!");
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
        if (!players[_player]) {
            return isValid; //Player is Not Found in Mapping
        }
        bytes32 playerHash = WORLD.hashPlayer(_player);
        if (players[_player] == playerHash) {
            isValid = true; //Hashes Match
        }
    }
    
    
    //Hashes a newly created Item and adds it to items mapping
    function setItemHash(address _item) internal {
        bytes32 itemHash = WORLD.hashItem(_item);
        items[_item] = itemHash;
    }

    function getItemSeed() internal {
        itemNonce++;
        return seed ^ itemNonce;
    }

    function getArenaSeed() internal {
        arenaNonce++;
        return seed ^ arenaNonce;
    }


    function itemIsValid(address _item) external returns (bool) {
        bytes32 _validHash = items[_item];
        require(_validHash != 0, "Address is Not a Familiar Item!"); //Don't bother trying to calculate a new hash if the address isn't found
        bytes32 _itemHash = WORLD.hashItem(_item);
        if (_validHash == _itemHash) {
            return true;
        } else {
            return false;
        }
    }

    function setPlayerHash(address _player) internal {
        bytes32 playerHash = WORLD.hashPlayer(_player);
        players[_player] = playerHash;
    }

    function grantItemReward(Player _player, ItemTier _tier) external isCompletedArena {
        Item rewardItem = WORLD.vault.generateReward(_tier, seed);
        require(isValidPlayer(_player), "Tried to Reward an Invalid Player");
        if (!isCommonItem(_tier)) { //Save some gas by not hashing common items that already exist in the mapping
            setItemHash(rewardItem);
        }
        _player.addItemToInventory(rewardItem);
        setPlayerHash(_player);

    }

    function closeArena(Arena _arena) external isActiveArena {
        if (!arena.status == Status.Complete) {
            revert("Failed to Close Arena - Status is Not Complete");
        }
        for (uint i = 0; i < _arena.players.length; i++) {
            PlayerState _playerState = arena.playerState[players[i]];
            for (uint j = 0; j < _playerState.itemRewards.length; j++) {
                _player.player.moveToVoid();
                _player.player.addItemToInventory(_playerState.itemRewards[j]);
            }
        }
        _arena.close();
    }


    function handleArena(Arena _arena) internal returns (bool arenaCanAdvance) {
        if (arena.status == Status.Active) {
            arena.advance();
            arenaCanAdvance = true;
        //Arena hit an Exit condition, Close it
        } else if (arena.status == Status.Complete) {
            closeArena(_arena);            
        } else if (arena.status == Status.Closed) {
            delete activeArenas[i];
        } else {
            revert ("Failed to Handle Arena - Unsupported Status!");
        }
    }

    function handleActiveArenas() internal returns (uint advancableArenas) {
        for (uint i = 0; i < activeArenas.length; i++){
            activeArenas[i].tick();
            advancableArenas++;
        }
    }

    function grantExperienceReward(Player _player, Skill _skill, uint256 _experience) external isCompletedArena {
        require(isValidPlayer(_player), "Tried to Grant XP to an Invalid Player!");
        _player.receiveExperience(_skill, _experience);
        setPlayerHash(_player);
    }

    function tick(uint256 _seed) external isOwner isNextTick {
        tickBlockHeight = block.number;
        seed = _seed;
        tickNumber++;
        uint advancableArenas = handleActiveArenas();
        emit GameTick(tickNumber, tickBlockHeight, advancableArenas);
    }

    function createArena(string _bossName) external {
        Arena arena = new Arena(getArenaSeed(), WORLD.arenaMaxTicks);
        Boss arenaBoss = new Boss(_bossName);
        arena.open(arenaBoss, tickNumber+1);
    }
}