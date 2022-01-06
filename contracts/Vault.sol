pragma solidity >=0.7.0 <0.9.0;

//SPDX-License-Identifier: UNLICENSED

import "./World.sol";
import "./enums/DamageType.sol";
import "./enums/WeaponType.sol";
import "./enums/ItemTier.sol";
import "./enums/EquipmentSlot.sol";
import "./enums/Skill.sol";
import "./structs/WeaponBase.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/structs/EnumerableSet.sol";

contract Vault {
    
    using EnumerableSet for EnumerableSet.UintSet;
    
    World constant private WORLD = World(0x992DA8eC2af8ec58E89E3293Fb3aaC8ebD7602B8); //TODO Update this with Actual Contract
    
    EnumerableSet.UintSet private weaponTypes; //Allow external access via values() in custom getter

    mapping(WeaponType => DamageType) public weaponDamageTypes;

    mapping(DamageType => Skill) public weaponSkillRequirements;
    
    modifier isOwner() {
        require(msg.sender == WORLD.owner());
        _;
    }

    function getDamageType(WeaponType _weaponType) public view returns (DamageType) {
        return weaponDamageTypes[_weaponType];
    }
  
    function getWeaponTypes() public view returns (uint[] memory) {
        return weaponTypes.values();
    }

    function getWeaponType(uint _seed) public view returns (uint) {
        uint seedIndex = _seed % weaponTypes.length();
        return weaponTypes.at(seedIndex);
    }

    function addWeapon(WeaponType _weaponType, DamageType _damageType) public returns (bool success) {
        success = weaponTypes.add(uint(_weaponType));
        weaponDamageTypes[_weaponType] = _damageType;
    }
    
    function getWeaponDamage(ItemTier _tier, uint _seed) public view returns (uint) {
        uint baseDamage = WORLD.baseWeaponDamage() ** uint(_tier);
        uint tierDamageRange = WORLD.damageMaxRange() * uint(_tier);
        uint damageModifier = _seed % tierDamageRange;
        return baseDamage + damageModifier;
    }

    function getWeaponSkill(DamageType _damageType) public view returns (Skill) {
        return weaponSkillRequirements[_damageType];
    }

    function getLevelRequirement(ItemTier _tier) public view returns (uint) {
        return 5 * _tier; //TODO Update this to calculate based on Seed w/ range factor like Weapon damage
    }

    function isUniqueItem(ItemTier _tier) internal pure returns (bool) {
        if (_tier >= ItemTier.Exotic) {
            return true;
        }
        return false;
    }
}