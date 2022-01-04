pragma solidity >=0.7.0 <0.9.0;

//SPDX-License-Identifier: UNLICENSED
import "./World.sol";
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

    EntityType public eType;

    mapping(EquipmentSlot => Item) equipment;
   
    mapping(Skill => uint256) experience;
    
    Item[] public inventory;

    uint256 public health;


    address public arena;

    uint public tile;


    World constant public WORLD = World(0x992DA8eC2af8ec58E89E3293Fb3aaC8ebD7602B8);
    
    // event for EVM logging
    event EntityCreated(address indexed owner, EntityType entityType);
    event AddedInventoryItem(Item indexed item);
    event EquippedItem(EquipmentSlot indexed slot, Item indexed item);
    event Moved(address indexed arena, uint oldTile, uint newTile);
    event GainedExperience(Skill indexed _skill, uint amount);
    event Death(address indexed arena, uint indexed tile);

    modifier isOwner() {
        require(msg.sender == owner, "Caller is Not Player Owner!");
        _;
    }

    modifier isWarden() {
        require(msg.sender == WORLD.warden(), "Caller is Not Current Warden!");
        _;
    }

    modifier isArena() {
        require(msg.sender == arena, "Caller is Not Current Arena!");
        _;
    }

    modifier canAttack() {
        require(WORLD.attackableEntities(eType), "Entity Cannot be Attacked!");
        _;
    }

    modifier onlyIfAlive() {
        require(isAlive(), "Entity is Not Alive!");
        _;
    }


    bool public isSafe;   // if True, player cannot be attacked by others
    
    address public owner;
    
    uint8 public level;
    
    //All Players must be created by World contract, caller of World's createPlayer function is passed in.  
    constructor(address _owner, EntityType _type) {
        owner = _owner;
        eType = _type;
        emit EntityCreated(owner, eType);
    }
    
    
    function addItemToInventory(Item _item) external isWarden {
        inventory.push(_item);
        emit AddedInventoryItem(_item);
    }

    function grantExperience(Skill _skill, uint _amount) internal {
        experience[_skill] += _amount;
        emit GainedExperience(_skill, _amount);
    }

    function getSkillLevel(Skill _skill) public view returns (uint) {
        return experience[_skill] % WORLD.levelMod();
    }

    function getCombatLevel() public view returns (uint) {
        return ((experience[Skill.Strength] + experience[Skill.Sorcery] + experience[Skill.Archery]) / 3 + experience[Skill.Defense] + experience[Skill.Life]) % WORLD.levelMod();
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
        EquipmentSlot itemSlot = inventory[_inventorySlot].slot();
        equipment[itemSlot] = inventory[_inventorySlot];
        emit EquippedItem(itemSlot, inventory[_inventorySlot]);
    }


    function setArena(address _arena) external isWarden {
        arena = _arena;
    }

    function moveTo(uint _targetTile) external isArena {
        emit Moved(arena, tile, _targetTile);
        tile = _targetTile;
    }

    function moveTowards(uint _targetTile, uint _rowShift) external isArena {
        uint newTile;
        if (tile < _targetTile) {
            if ((_targetTile - tile) > _rowShift) { //We can move by one row instead of one column
                newTile = tile + (1 * _rowShift);
            } else {
                newTile = tile + 1; //Otherwise, simply move one column towards your objective
            }
        } else {
            if ((tile - _targetTile) > _rowShift) {
                newTile = tile -  (1 * _rowShift);
            } else {
                newTile = tile - 1;
            }
        }
        require(newTile > 0, "New Tile Value is Invalid!"); //Entities can never move to home tile
        this.moveTo(newTile);
    }

    function moveToVoid() external isWarden {
        this.moveTo(0);
    }

    

    //TODO Update this once we support Armor
    function getDamageReduction() public view canAttack returns (uint) {
        return getCombatLevel() * WORLD.baseDamageReduction();
    }

    function getDamageOutput() public view canAttack returns (uint) {
        Weapon weapon = Weapon(address(equipment[EquipmentSlot.Weapon]));
        return getCombatLevel() * weapon.damage();
    }

    function attack() external canAttack onlyIfAlive isArena {
        Weapon weapon = Weapon(address(equipment[EquipmentSlot.Weapon]));
        grantExperience(weapon.skill(), getDamageOutput());
    }

    function damage(uint _damageAmount) external canAttack onlyIfAlive isArena returns (bool) {
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

    function heal(uint _healAmount) external canAttack isArena {
        if ((health + _healAmount) > getMaxHealth()) {
            health = getMaxHealth();
        } else {
            health += _healAmount;
        }
    }
}
