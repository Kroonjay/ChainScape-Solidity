pragma solidity >=0.7.0 <0.9.0;

//SPDX-License-Identifier: UNLICENSED

import "./World.sol";
import "./Weapon.sol";
import "./Boss.sol";
import "./enums/DamageType.sol";
import "./enums/WeaponType.sol";
import "./enums/ItemTier.sol";
import "./enums/EquipmentSlot.sol";
import "./structs/WeaponBase.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/structs/EnumerableSet.sol";

contract Vault {
    
    using EnumerableSet for EnumerableSet.AddressSet;

    event ItemCreated(ItemTier indexed tier, EquipmentSlot indexed slot);
    
    address public owner;
    
    World constant private WORLD = World(0x0b2Ec57f2Cee82C2E66b3Bf624e716Ff77126906); //TODO Update this with Actual Contract
    
    mapping(ItemTier => WeaponBase[]) public weaponBases;
    
    mapping(ItemTier =>mapping(EquipmentSlot => uint16)) private vaultCounter;
    
    mapping(ItemTier =>mapping(EquipmentSlot => Item[])) private commonItems; //Common Items are pre-generated and can be shared among users.  All common items should be owned by the current warden.  
    
    EnumerableSet.UintSet private weaponTypes;

    EnumerableSet.UintSet private damageTypes; //Allow external access via values() in custom getter
    
    modifier isOwner() {
        require(msg.sender == WORLD.owner());
        _;
    }

    modifier isWarden() {
        require(msg.sender == WORLD.warden());
        _;
    }

    constructor() {
        owner = msg.sender;
        rewardNonce = 1;
    }

    function getDamageTypes() public view returns (uint[]) {
        return damageTypes.values();
    }
  
    function getWeaponTypes() public view returns (uint[]) {
        return weaponTypes.values();
    }

    function getWeaponType(uint _seed) public view returns (uint) {
        uint seedIndex = _seed % weaponTypes.length();
        return weaponTypes.at(seedIndex);
    }
    
    function getDamageModifier(ItemTier _tier, uint _seed) public view returns (uint) {
        uint256 tierBaseDamage = WORLD.baseWeaponDamage() ** uint(_tier);
        uint256 weaponDamageRange = tierBaseDamage / (WORLD.damageMaxRange() / 100);
        uint256 weaponDamageFactor = _seed % weaponDamageRange;
        return tierBaseDamage + weaponDamageFactor;
    }

    function addWeaponType(WeaponType _weaponType) public isOwner{
        require(weaponTypes.add(_weaponType), "Value already Present!");
    }

    function addDamageType(DamageType _damageType) public isOwner{
        require(damageTypes.add(_damageType), "Value already Present!");
    }

    function isUniqueItem(ItemTier _tier) internal pure returns (bool) {
        if (_tier >= ItemTier.Exotic) {
            return true;
        }
        return false;
    }
}