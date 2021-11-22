pragma solidity >=0.7.0 <0.9.0;

//SPDX-License-Identifier: UNLICENSED


import "./structs/Equipment.sol";
import "./structs/Experience.sol";

import "./enums/EquipmentSlot.sol";
import "./enums/StarterClass.sol";
import "./enums/Skill.sol";


contract World {
   
   event WardenSet(address indexed oldWarden, address indexed newWarden);
   event VaultSet(address indexed oldVault, address indexed newVault);
   
   
   
    address public owner;
    
    address public warden;
    address public vault;
    
    
    uint8 public blocksPerTick; //Determines number of blocks between Game Ticks, called by Warden
    
    uint256 starterExperience;
    
    uint32 levelMod = 1000000;
    
    mapping (StarterClass => Equipment) starterEquipmentMapping;
    
    mapping (StarterClass => Experience) starterExperienceMapping;
    
    modifier isOwner() {
        // If the first argument of 'require' evaluates to 'false', execution terminates and all
        // changes to the state and to Ether balances are reverted.
        // This used to consume all gas in old EVM versions, but not anymore.
        // It is often a good idea to use 'require' to check if functions are called correctly.
        // As a second argument, you can also provide an explanation about what went wrong.
        require(msg.sender == owner, "Caller is not owner");
        _;
    }
    
    constructor() {
       owner = msg.sender;
    }
   
    function getStarterExperience (StarterClass starterClass) external view returns (Experience memory) {
       return starterExperienceMapping[starterClass];
    }
   
    function setStarterSkill (StarterClass starterClass, Skill skill, uint256 skillXp) public isOwner {
       if (skill == Skill.Strength) {
           starterExperienceMapping[starterClass].strength = skillXp;
       } else if (skill == Skill.Sorcery) {
           starterExperienceMapping[starterClass].sorcery = skillXp;
       } else if (skill == Skill.Archery) {
           starterExperienceMapping[starterClass].archery = skillXp;
       } else if (skill == Skill.Stamina) {
           starterExperienceMapping[starterClass].stamina = skillXp;
       } else if (skill == Skill.Life) {
           starterExperienceMapping[starterClass].life = skillXp;
       } else if (skill == Skill.Defense) {
           starterExperienceMapping[starterClass].defense = skillXp;
       } else {
           revert ("Skill is Not Yet Supported!");
       }
   }
   
   function getStarterEquipment (StarterClass starterClass) external view returns (Equipment memory) {
       return starterEquipmentMapping[starterClass];
   }
   
   function setStarterItem (StarterClass starterClass, EquipmentSlot equipmentSlot, address newItem) public isOwner {
       //TODO Figure out a better way to do this
       if (equipmentSlot == EquipmentSlot.Helmet) {
           starterEquipmentMapping[starterClass].helmet = newItem;
       } else if (equipmentSlot == EquipmentSlot.Armor) {
           starterEquipmentMapping[starterClass].armor = newItem;
       } else if (equipmentSlot == EquipmentSlot.Weapon) {
           starterEquipmentMapping[starterClass].weapon = newItem;
       } else if (equipmentSlot == EquipmentSlot.Blessing) {
           starterEquipmentMapping[starterClass].blessing = newItem;
       } else {
           //Uhh should probably make sure this isn't a bad idea
           revert("Equipment Slot is Not Yet Supported!");
       }
   }
   
   function getPlayerLevel (Experience memory _playerXp) external view returns (uint256) {
       return ((_playerXp.strength + _playerXp.sorcery + _playerXp.archery) / 3 + _playerXp.defense + _playerXp.life) % levelMod;
   }
   

   function setWarden(address newWarden) public isOwner {
       emit WardenSet(warden, newWarden);
       warden = newWarden;
   }
   
   function setVault(address _newVault) public isOwner {
        emit VaultSet(vault, _newVault);
        vault = _newVault;
   }
   
}  