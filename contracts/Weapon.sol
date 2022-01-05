// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;
import "./Item.sol";
import "./enums/EquipmentSlot.sol";
import "./enums/WeaponType.sol";
import "./enums/DamageType.sol";
import "./enums/Skill.sol";
import "./structs/WeaponBase.sol";
import "./Vault.sol";

contract Weapon is Item {
    
    
    string public weaponType;
    
    uint256 public damage;
    
    
    DamageType public damageType;
    
    Skill public skill;
    
    uint256 public levelRequirement; //The skill (Strength, Sorcery, Archery) is determined based on DamageType
    
    
    constructor(WeaponBase memory _weaponBase) Item(EquipmentSlot.Weapon, _weaponBase.tier) {
        owner = msg.sender;
    }

    function getHash() external view returns (bytes32) {
        return keccak256(abi.encodePacked(owner, weaponType, damageType, damage, levelRequirement));
    }

    function setWeaponType() private {
        Vault vault = Vault(WORLD.vault());
    }
    
}