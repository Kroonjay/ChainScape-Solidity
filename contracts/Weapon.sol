// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;
import "./Item.sol";
import "./enums/EquipmentSlot.sol";
import "./enums/WeaponType.sol";
import "./enums/DamageType.sol";
import "./enums/Skill.sol";
import "./Vault.sol";

contract Weapon is Item {
    
    
    uint public weaponType;
    
    uint public damage;
    
    DamageType public damageType;
    
    Skill public skillRequirement;
    
    uint public levelRequirement; //The skill (Strength, Sorcery, Archery) is determined based on DamageType
    
    bool public identified;
    
    constructor(ItemTier _tier, uint _seed, address _owner) Item(EquipmentSlot.Weapon, _tier, _seed, _owner) {
    }

    function getHash() external view returns (bytes32) {
        return keccak256(abi.encodePacked(owner, weaponType, damageType, damage, levelRequirement));
    }

    function identify() public isOwner {
        Vault vault = Vault(WORLD.vault());
        weaponType = vault.getWeaponType(seed);
        damageType = vault.getDamageType(weaponType);
        damage = vault.getWeaponDamage(tier, seed);
        skillRequirement = vault.getWeaponSkill(damageType);
        levelRequirement = vault.getLevelRequirement(tier);
    }
    
}