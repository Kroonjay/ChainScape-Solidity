pragma solidity >=0.7.0 <0.9.0;

//SPDX-License-Identifier: UNLICENSED

import "./World.sol";
import "./Arena.sol";
import "./Item.sol";
import "./Weapon.sol";
import "./structs/Equipment.sol";
import "./structs/Experience.sol";

import "./enums/StarterClass.sol";
import "./enums/EquipmentSlot.sol";
import "./enums/Skill.sol";
import "./enums/Objective.sol";
import "./enums/EntityType.sol";
import "./enums/Status.sol";

contract Entity {
    
    string name;

    EntityType public eType;

    mapping(EquipmentSlot => Item) equipment;
   
    mapping(Skill => uint256) experience;
    
    Item[] public inventory;

    uint256 public health;


    Arena public arena;

    uint public tile;


    World constant private WORLD = World(0x12345566);
    
    // event for EVM logging
    event EntityCreated(address indexed owner, bytes32 indexed name, EntityType entityType);
    event AddedInventoryItem(address indexed item);
    event EquippedItem(EquipmentSlot indexed slot, address indexed item);
    event Moved(address indexed arena, uint oldTile, uint newTile);
    event GainedExperience(Skill indexed _skill, uint amount);
    event Death(address indexed arena, uint indexed tile);

    modifier isOwner() {
        require(msg.sender == owner, "Caller is Not Player Owner!");
        _;
    }

    modifier isWorld() {
        require(msg.sender == WORLD, "Caller is Not World!");
        _;
        
    }

    modifier isWarden() {
        require(msg.sender == WORLD.warden, "Caller is Not Current Warden!");
        _;
    }

    modifier isActiveArena() {
        require(msg.sender == arena, "Caller is Not Current Arena!");
        require(arena.status == Status.Active, "Caller Arena is Not Active!");
        _;
    }

    modifier canAttack() {
        require(WORLD.attackableEntities[eType], "Entity Cannot be Attacked!");
        _;
    }

    modifier onlyIfAlive() {
        require(isAlive(), "Entity is Not Alive!");
        _;
    }


    


    bool public isSafe;   // if True, player cannot be attacked by others
    
    address public owner;
    
    uint8 public level;

    Objective public objective;

    
    
    //All Players must be created by World contract, caller of World's createPlayer function is passed in.  
    constructor(string _name,  EntityType _type) {
        require(msg.sender == WORLD, "Only the World Contract can Call this function!");
        name = _name;
        owner = msg.sender;
        eType = _type;
        emit EntityCreated(owner, name, eType);
    }
    
    
    function addItemToInventory(Item _item) external isWarden {
        inventory.push(_item);
        emit AddedInventoryItem(_item);
    }

    function grantExperience(Skill _skill, uint _amount) external isActiveArena {
        experience[_skill] += amount;
        emit GainedExperience(_skill, _amount);
    }

    function getSkillLevel(Skill _skill) public view returns (uint) {
        return experience[_skill] % WORLD.levelMod;
    }

    function getCombatLevel() public view returns (uint) {
        return ((experience[Skill.Strength] + experience[Skill.Sorcery] + experience[Skill.Archery]) / 3 + experience[Skill.Defense] + experience[Skill.Life]) % WORLD.levelMod;
    }

    //TODO Update this to include more than just base Life XP
    function getMaxHealth() public view returns (uint) {
        return experience[Skill.Life];
    }

    function isAlive() public view returns (bool) {
        if (health > 0) {
            return true;
        } else {
            return false;
        }
    }

    //TODO Level Requirements for Items currently doesn't work
    function equipItem(uint8 _inventorySlot) public isOwner {
        require(_inventorySlot < inventory.length, "Inventory Slot is Invalid");
        Item equippableItem = inventory[_inventorySlot];
        EquipmentSlot itemSlot = equippableItem.slot;
        equipment[itemSlot] = equippableItem;
        emit EquippedItem(itemSlot, equippableItem);
    }


    function setArena(Arena _arena) external isWarden {
        require(arena.status != Status.Active, "Entity is Already in an Active Arena!");
        require(_arena.status == Status.New, "Entity Can Only Join New Arenas");
        arena = _arena;
    }

    function moveTo(uint _targetTile) internal {
        emit Moved(arena, tile, _targetTile);
        tile = _targetTile;
    }

    function moveTowards(uint _targetTile) external isActiveArena {
        uint rowShift = arena.gridColumns;
        uint newTile;
        if (tile < _targetTile) {
            if ((_targetTile - tile) > rowShift) { //We can move by one row instead of one column
                newTile = tile + (1 * rowShift);
            } else {
                newTile = tile + 1; //Otherwise, simply move one column towards your objective
            }
        } else {
            if ((tile - _targetTile) > rowShift) {
                newTile = tile + (-1 * rowShift);
            } else {
                newTile = tile - 1;
            }
        }
        require(newTile > 0, "New Tile Value is Invalid!"); //Entities can never move to home tile
        moveTo(newTile);
    }

    function moveToVoid() external isWarden {
        moveTo(0);
    }

    

    //TODO Update this once we support Armor
    function getDamageReduction() public view canAttack {
        return getCombatLevel() * WORLD.baseDamageReduction;
    }

    function getDamageOutput() public view canAttack {
        Weapon weapon = equipment[EquipmentSlot.Weapon];
        return getCombatLevel() * weapon.damage;
    }

    function attack() external canAttack onlyIfAlive isActiveArena {
        uint damageOutput = getDamageOutput();
        grantExperience(equipment[EquipmentSlot.Weapon].skill, damageOutput);
    }

    function damage(uint _damageAmount) external canAttack onlyIfAlive isActiveArena returns (bool) {
        //Damage is Fatal
        if (_damageAmount < health) {
            health = 0;
            emit Death(arena, tile);
            return true;
        } else {
            grantExperience(Skill.Life, _damageAmount);
            grantExperience(Skill.Defense, _damageAmount);
            health -= _damageAmount;
            return false;
        }
    }

    function heal(uint _healAmount) external canAttack isActiveArena {
        if ((health + _healAmount) > getMaxHealth()) {
            health = getMaxHealth();
        } else {
            health += _healAmount;
        }
    }


}
