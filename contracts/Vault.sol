pragma solidity >=0.7.0 <0.9.0;

//SPDX-License-Identifier: UNLICENSED

import "./World.sol";
import "./enums/DamageType.sol";
import "./enums/WeaponType.sol";
import "./enums/ItemTier.sol";
import "./enums/EquipmentSlot.sol";
import "./structs/WeaponBase.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/structs/EnumerableSet.sol";

contract Vault {
    
    using EnumerableSet for EnumerableSet.UintSet;
    
    World constant private WORLD = World(0x992DA8eC2af8ec58E89E3293Fb3aaC8ebD7602B8); //TODO Update this with Actual Contract
    
    EnumerableSet.UintSet private weaponTypes; //Allow external access via values() in custom getter

    mapping(WeaponType => DamageType) public weaponDamageTypes; 
    
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
    
    function getDamageModifier(ItemTier _tier, uint _seed) public view returns (uint) {
        uint256 tierBaseDamage = WORLD.baseWeaponDamage() ** uint(_tier);
        uint256 weaponDamageRange = tierBaseDamage / (WORLD.damageMaxRange() / 100);
        uint256 weaponDamageFactor = _seed % weaponDamageRange;
        return tierBaseDamage + weaponDamageFactor;
    }

    function isUniqueItem(ItemTier _tier) internal pure returns (bool) {
        if (_tier >= ItemTier.Exotic) {
            return true;
        }
        return false;
    }
}