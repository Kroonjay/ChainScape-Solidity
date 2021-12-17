pragma solidity >=0.7.0 <0.9.0;

//SPDX-License-Identifier: UNLICENSED

import "./World.sol";
import "./Item.sol";
import "./Weapon.sol";
import "./enums/DamageType.sol";
import "./enums/WeaponType.sol";
import "./enums/ItemTier.sol";
import "./enums/EquipmentSlot.sol";
import "./structs/WeaponBase.sol";


contract Vault {
    
    event ItemCreated(ItemTier indexed tier, EquipmentSlot indexed slot);
    
    address public owner;
    
    World constant private WORLD = World(0x0b2Ec57f2Cee82C2E66b3Bf624e716Ff77126906); //TODO Update this with Actual Contract
    
    string[3] public damageTypes;
    
    mapping(ItemTier => WeaponBase[]) public weaponBases;
    
    mapping(ItemTier =>mapping(EquipmentSlot => uint16)) private vaultCounter;
    
    mapping(ItemTier =>mapping(EquipmentSlot => Item[])) private commonItems; //Common Items are pre-generated and can be shared among users.  All common items should be owned by the current warden.  


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
        require(msg.sender == WORLD.warden());
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
    
    function _generateDamageMod(ItemTier _tier, uint256 _seed) internal view returns (uint256) {
        uint256 tierBaseDamage = WORLD.baseWeaponDamage() ** uint(_tier);
        uint256 weaponDamageRange = tierBaseDamage / (WORLD.damageMaxRange() / 100);
        uint256 weaponDamageFactor = _seed % weaponDamageRange; //TODO Add an Event Here
        return tierBaseDamage + weaponDamageFactor;
    }

    function _createWeapon(WeaponBase memory _weaponBase) internal returns (Weapon) {
        Weapon newWeapon = new Weapon(_weaponBase);
        emit ItemCreated(newWeapon.tier(), EquipmentSlot.Weapon);
        return newWeapon;
    }

    function isUniqueItem(ItemTier _tier) internal pure returns (bool) {
        if (_tier >= ItemTier.Exotic) {
            return true;
        }
        return false;
    }
    
    //Items with tiers under exotic use pre-set contracts to save gas
    function _generateCommonReward(ItemTier _tier, uint256 _seed) internal isWarden returns (Item) {
        uint itemCount = vaultCounter[_tier][EquipmentSlot.Weapon]; //TODO Fix this to work for more than just weapons
        uint seedIndex = mulmod(_seed, rewardNonce, itemCount);
        setRewardNonce();
        return commonItems[_tier][EquipmentSlot.Weapon][seedIndex];
    }   

    function _generateUniqueReward(ItemTier _tier, uint256 _seed) internal isWarden returns (Item)  {
        uint itemCount = vaultCounter[_tier][EquipmentSlot.Weapon]; //TODO Fix this to work for more than just weapons
        uint seedIndex = mulmod(_seed, rewardNonce, itemCount);
        WeaponBase memory rewardBase = weaponBases[_tier][seedIndex];
        rewardBase.damage = _generateDamageMod(_tier, _seed);
        return _createWeapon(rewardBase);
    }

    function generateReward(ItemTier _tier, uint256 _seed) external isWarden returns (Item) {
        if (isUniqueItem(_tier)) {
            return _generateUniqueReward(_tier, _seed);
        } else {
            return _generateCommonReward(_tier, _seed);
        }
    }
    
    function addWeaponBase(ItemTier _tier, WeaponBase memory _weaponBase) public isOwner {
        weaponBases[_tier].push(_weaponBase);
        addToVaultCount(_tier, EquipmentSlot.Weapon); //TODO Add an Event Here
    }

    function addCommonItem(Item _item) external isOwner {
        ItemTier _itemTier = _item.tier();
        require(_itemTier < ItemTier.Exotic, "Item Tier Invalid, Must be Less than Exotic!"); //All Tiers < Exotic are considered "Common"
        commonItems[_itemTier][_item.slot()].push(_item);
        addToVaultCount(_itemTier, _item.slot());
    }
}