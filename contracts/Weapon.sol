// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;
import "./Warden.sol";
import "./Item.sol";
import "./enums/EquipmentSlot.sol";
import "./enums/WeaponType.sol";
import "./enums/DamageType.sol";
import "./enums/Skill.sol";

import "./structs/WeaponBase.sol";


contract Weapon is Item {
    
    
    string public weaponType;
    
    uint256 public damage;
    
    uint256 public seed;
    
    DamageType public damageType;
    
    Skill public skill;
    
    uint256 public levelRequirement; //The skill (Strength, Sorcery, Archery) is determined based on DamageType
    
    
    constructor(ItemTier _tier, uint256 _itemSeed) Item(EquipmentSlot.Weapon, _tier) {
        owner = msg.sender;
    }
    
    function setWeaponType() private isUnidentified {
        
    }
    
}