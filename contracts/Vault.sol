pragma solidity >=0.7.0 <0.9.0;

//SPDX-License-Identifier: UNLICENSED

import "./World.sol";
import "./Item.sol";
import "./enums/DamageType.sol";
import "./enums/WeaponType.sol";
import "./enums/ItemTier.sol";
import "./enums/EquipmentSlot.sol";
import "./structs/WeaponBase.sol";


contract Vault {
    
    event ItemCreated(uint indexed seed, uint indexed tier, uint indexed slot);
    
    address public owner;
    
    World constant private WORLD = World(0x12345566); //TODO Update this with Actual Contract
    
    string[3] public damageTypes;
    
    mapping(ItemTier => WeaponBase[]) public weaponBases;
    
    mapping(ItemTier =>mapping(EquipmentSlot => uint16)) private vaultCounter;
    
    mapping(ItemTier =>mapping(EquipmentSlot => address[])) private commonItems; //Common Items are pre-generated and can be shared among users.  All common items should be owned by the current warden.  


    string[] public arcaneWeapons;
    
    string[] public projectileWeapons;
    
    string[] public tiers;
    
    uint256 private rewardNonce;
    
    DamageType public damageType;
    

    

    
    
    
    modifier isOwner() {
        require(msg.sender == owner);
        _;
    }

    modifier isWarden() {
        require(msg.sender == WORLD.warden);
        _;
    }

    modifier isCommonItem(ItemTier _tier) {
        require(_tier < ItemTier.Exotic, "Item Tier Must be Less than Exotic");
        _;
    }
    
    constructor() {
        owner = msg.sender;
        rewardNonce = 1;
    }
  
    function setRewardNonce() internal {
        rewardNonce++;
    }
    
    function addToVaultCount(ItemTier _tier, EquipmentSlot _slot) internal {
         vaultCounter[_tier][_slot]++; //Not positive this works but we'll see
    }
    
    function _generateDamageMod(ItemTier _tier, uint256 _seed) internal pure returns (uint256) {
        uint256 tierBaseDamage = baseWeaponDamage ** uint(_tier);
        uint256 weaponDamageRange = tierBaseDamage / (WORLD.damageMaxRange / 100);
        uint256 weaponDamageFactor = _seed % weaponDamageRange; //TODO Add an Event Here
        return tierBaseDamage + weaponDamageFactor;
    }
    
    function _generateWeaponBase(ItemTier _tier, uint256 _seed) internal returns(WeaponBase memory) {
        uint16 itemCount = vaultCounter[_tier][EquipmentSlot.Weapon];
        uint256 seedIndex = mulmod(_seed, rewardNonce, itemCount);
        WeaponBase storage weaponBase = weaponBases[_tier][EquipmentSlot.Weapon][seedIndex];
        require(weaponBase.isValid, "Failed to Retrieve Weapon Base!");
        weaponBase.damage = generateDamageMod(_tier, _seed);
        return weaponBase;
    }

    function _createWeapon(WeaponBase _weaponBase) internal pure returns (Weapon) {
        Weapon newWeapon = new Weapon(_weaponBase);
        emit ItemCreated(newWeapon.seed, newWeapon.tier, EquipmentSlot.Weapon);
        return newWeapon;
    }
    
    //Items with tiers under exotic use pre-set contracts to save gas
    function _generateCommonReward(ItemTier _tier, uint256 _seed) internal isWarden returns (Item) {
        require(isCommonItem(_tier), "Item Tier is Invalid!");
        uint itemCount = vaultCounter[_tier][EquipmentSlot.Weapon]; //TODO Fix this to work for more than just weapons
        uint seedIndex = mulmod(_seed, rewardNonce, itemCount);
        setRewardNonce();
        return commonItems[_tier][EquipmentSlot.Weapon][seedIndex];
    }   

    function _generateUniqueReward(ItemTier _tier, uint256 _seed) internal isWarden returns (Item)  {
        require(!isCommonItem(_tier), "Item Tier is Invalid");
        uint itemCount = vaultCounter[_tier][EquipmentSlot.Weapon]; //TODO Fix this to work for more than just weapons
        uint seedIndex = mulmod(_seed, rewardNonce, itemCount);
        WeaponBase memory rewardBase = weaponBases[_tier][seedIndex];
        return _createWeapon(rewardBase);
    }

    function generateReward(ItemTier _tier, uint256 _seed) external isWarden returns (Item) {
        if (isCommonItem(_tier)) {
            return _generateCommonReward(_tier, _seed);
        } else {
            return _generateUniqueReward(_tier, _seed);
        }
    }
    
    function addWeaponBase(ItemTier _tier, WeaponBase memory _weaponBase) public isOwner {
        equipmentItems[_tier][EquipmentSlot.Weapon].push(_weaponBase);
        addToVaultCount(_tier, EquipmentSlot.Weapon); //TODO Add an Event Here
    }

    function addCommonItem(Item _item) external isOwner {
        require(World.warden.itemIsValid(_item), "Item is Invalid!");
        require(_item.tier < ItemTier.Exotic, "Item Tier Invalid, Must be Less than Exotic!"); //All Tiers < Exotic are considered "Common"
        commonItems[_item.tier][_item.slot].push(_item);
        addToVaultCount(_item.tier, _item.slot);
    }
}