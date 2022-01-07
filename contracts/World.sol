pragma solidity >=0.7.0 <0.9.0;

//SPDX-License-Identifier: UNLICENSED


import "./structs/Equipment.sol";
import "./structs/Experience.sol";
import "./enums/EquipmentSlot.sol";
import "./enums/StarterClass.sol";
import "./enums/Skill.sol";
import "./enums/EntityType.sol";
import "./enums/DamageType.sol";
import "./enums/WeaponType.sol";


contract World {
   
   event WardenSet(address indexed oldWarden, address indexed newWarden);
   event VaultSet(address indexed oldVault, address indexed newVault);
   event PlayerCreated(address indexed newPlayer, address indexed owner, StarterClass indexed starterClass);
   
   
    address public zima;
    
    address public warden;
    address public vault;
    
    
    uint public blocksPerTick; //Determines number of blocks between Game Ticks, called by Warden
    
    uint starterExperience;
    
    uint public levelMod;

    uint public baseWeaponDamage;

    uint public damageMaxRange;

    uint public baseDamageReduction;

    uint public experiencePerHit;

    uint public arenaMaxTicks;

    uint public inventorySlots;

    mapping(EntityType => bool) public attackableEntities;





    modifier isZima() {
        require(msg.sender == zima, "Caller is not Zima!");
        _;
    }
    
    constructor() {
       zima = msg.sender;
       blocksPerTick = 2;
       starterExperience = 1000000;
       levelMod = 1000000;
       baseWeaponDamage = 50;
       damageMaxRange = 20;
       baseDamageReduction = 50;
       experiencePerHit = 1;
       arenaMaxTicks = 100;
    }
   

    function setWarden(address newWarden) public isZima {
       emit WardenSet(warden, newWarden);
       warden = newWarden;
    }
   
    function setVault(address _newVault) public isZima {
        emit VaultSet(vault, _newVault);
        vault = _newVault;
    }

    function setBlocksPerTick(uint _blocks) external isZima {
        blocksPerTick = _blocks;
    }

    function setBaseWeaponDamage(uint _damage) external isZima {
        baseWeaponDamage = _damage;
    }

    function setDamageMaxRange(uint _range) external isZima {
        damageMaxRange = _range;
    }

    function setBaseDamageReduction(uint _damage) external isZima {
        baseDamageReduction = _damage;
    }

    function setExperiencePerHit(uint _xp) external isZima {
        experiencePerHit = _xp;
    }

    function setArenaMaxTicks(uint _ticks) external isZima {
        arenaMaxTicks = _ticks;
    }

    function setInventorySlots(uint _slots) external isZima {
        inventorySlots = _slots;
    }

    function updateAttackableEntity(EntityType _eType, bool canAttack) external isZima {
        attackableEntities[_eType] = canAttack;
    }

}  