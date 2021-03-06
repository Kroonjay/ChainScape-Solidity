pragma solidity >=0.7.0 <0.9.0;

//SPDX-License-Identifier: UNLICENSED

import "./World.sol";
import "./enums/DamageType.sol";
import "./enums/WeaponType.sol";
import "./enums/ItemTier.sol";
import "./enums/EquipmentSlot.sol";
import "./enums/Skill.sol";

import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/structs/EnumerableSet.sol";

contract Vault {
    
    using EnumerableSet for EnumerableSet.UintSet;
    
    event WeaponAdded(WeaponType indexed _weaponType, DamageType indexed _damageType);


    World constant private WORLD = World(0x8Fde71F1A705989aEB1675e8E45798B5690a8Aee); //TODO Update this with Actual Contract
    
    EnumerableSet.UintSet private weaponTypes; //Allow external access via values() in custom getter

    mapping(uint => WeaponType) public weaponTypeMap; //Allows us to retrieve a WeaponType instead of a standard uint

    mapping(WeaponType => DamageType) public weaponDamageTypes;

    mapping(DamageType => Skill) public weaponSkillRequirements;
    
    modifier isZima() {
        require(msg.sender == WORLD.zima());
        _;
    }

    function getDamageType(WeaponType _weaponType) public view returns (DamageType) {
        return weaponDamageTypes[_weaponType];
    }
  
    function getWeaponTypes() public view returns (uint[] memory) {
        return weaponTypes.values();
    }

    function getWeaponType(uint _seed) public view returns (WeaponType) {
        uint seedIndex = _seed % weaponTypes.length();
        return weaponTypeMap[weaponTypes.at(seedIndex)];
    }

    function addWeapon(WeaponType _weaponType, DamageType _damageType) public isZima returns (bool success) {
        success = weaponTypes.add(uint(_weaponType));
        if(success) {
            weaponTypeMap[uint(_weaponType)] = _weaponType; //Don't update the mapping unless we have a new WeaponType
            emit WeaponAdded(_weaponType, _damageType);
        }
        weaponDamageTypes[_weaponType] = _damageType; //Allows us to update DamageType for existing weapons
    }
    
    function getWeaponDamage(ItemTier _tier, uint _seed) public view returns (uint) {
        uint baseDamage = WORLD.baseWeaponDamage() ** uint(_tier);
        uint tierDamageRange = WORLD.damageMaxRange() * uint(_tier);
        uint damageModifier = _seed % tierDamageRange;
        return baseDamage + damageModifier;
    }

    function setWeaponSkillRequirement(DamageType _damageType, Skill _skill) public isZima {
        weaponSkillRequirements[_damageType] = _skill;
    }

    function getLevelRequirement(ItemTier _tier) public pure returns (uint) {
        return 5 * uint(_tier); //TODO Update this to calculate based on Seed w/ range factor like Weapon damage
    }

    function isUniqueItem(ItemTier _tier) internal pure returns (bool) {
        if (_tier >= ItemTier.Exotic) {
            return true;
        }
        return false;
    }
}