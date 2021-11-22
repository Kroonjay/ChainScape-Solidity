// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;
import "./Warden.sol";
import "./Item.sol";
import "./enums/EquipmentSlot.sol";
import "./enums/WeaponType.sol";
import "./enums/DamageType.sol";

contract Weapon is Item {
    
    
    string public weaponType;
    
    uint256 public damage;
    
    Warden private warden;
    
    uint256 public itemSeed;
    
    DamageType public damageType;
    
    bool public isIdentified;
    
    uint256 public levelRequirement; //The skill (Strength, Sorcery, Archery) is determined based on DamageType
    
    
    constructor(ItemTier _tier, uint256 _itemSeed) Item(EquipmentSlot.Weapon, _tier) {
        owner = msg.sender;
        warden = world;
        isIdentified = false;
    }
    
    function setWeaponType() private isUnidentified {
        
    }
    
    function identify() public isOwner isUnidentified {
        
    }
}