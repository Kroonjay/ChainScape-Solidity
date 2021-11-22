pragma solidity >=0.7.0 <0.9.0;

//SPDX-License-Identifier: UNLICENSED

import "./World.sol";
import "./enums/DamageType.sol";
import "./enums/WeaponType.sol";
import "./enums/ItemTier.sol";
import "./enums/EquipmentSlot.sol";

contract Vault {
    
    struct WeaponBase {
        DamageType damageType;
        WeaponType weaponType;
        uint256 damage;
        uint8 attackSpeed;
        bool isValid; //Used to check if item exists in mapping
    }
    
    address public owner;
    
    World constant private WORLD = World(0x12345566); //TODO Update this with Actual Contract
    
    string[3] public damageTypes;
    
    mapping(ItemTier =>mapping(EquipmentSlot => WeaponBase[])) public equipmentItems;
    
    mapping(ItemTier =>mapping(EquipmentSlot => uint16)) private equipmentItemCounts;
    
    string[] public arcaneWeapons;
    
    string[] public projectileWeapons;
    
    string[] public tiers;
    
    uint256 private itemNonce;
    
    DamageType public damageType;
    
    uint256 private damageMaxRange;
    
    uint256 private baseWeaponDamage;
    
    
    
    modifier isOwner() {
        require(msg.sender == owner);
        _;
    }
    
    constructor() {
        owner = msg.sender;
        itemNonce = 1;
    }
  
    function setItemNonce() private {
        itemNonce++;
    }
    
    function addToVaultCount(ItemTier _tier, EquipmentSlot _slot) private {
         equipmentItemCounts[_tier][_slot]++; //Not positive this works but we'll see
    }
    
    function generateDamageMod(ItemTier _tier, uint256 _seed) private returns (uint256) {
        uint256 tierBaseDamage = baseWeaponDamage ** uint(_tier);
        uint256 weaponDamageRange = tierBaseDamage / (damageMaxRange / 100);
        uint256 weaponDamageFactor = _seed % weaponDamageRange; //TODO Add an Event Here
        return tierBaseDamage + weaponDamageFactor;
    }
    
    function generateWeapon(ItemTier _tier, uint256 _seed) public returns(WeaponBase memory) {
        uint16 itemCount = equipmentItemCounts[_tier][EquipmentSlot.Weapon];
        uint256 seedIndex = mulmod(_seed, itemNonce, itemCount);
        WeaponBase storage weaponBase = equipmentItems[_tier][EquipmentSlot.Weapon][seedIndex];
        require(weaponBase.isValid, "Failed to Retrieve Weapon Base!");
        weaponBase.damage = generateDamageMod(_tier, _seed);
        return weaponBase;
    }
    
    function addWeapon(ItemTier _tier, WeaponBase memory _weaponBase) public isOwner {
        equipmentItems[_tier][EquipmentSlot.Weapon].push(_weaponBase);
        addToVaultCount(_tier, EquipmentSlot.Weapon); //TODO Add an Event Here
    }
}