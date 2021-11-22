pragma solidity >=0.7.0 <0.9.0;

//SPDX-License-Identifier: UNLICENSED

import "./World.sol";


import "./structs/Equipment.sol";
import "./structs/Experience.sol";

import "./enums/StarterClass.sol";
import "./enums/EquipmentSlot.sol";
import "./enums/Skill.sol";

contract Player {
    
    bytes32 name;
    Equipment public equipment;
   
    Experience public experience;
    
    address public worldAddress;
    
    World private world = World(worldAddress);
    
    // event for EVM logging
    event PlayerCreated(address indexed owner, bytes32 indexed name);
    event PlayerClaimedStarterPack(address indexed owner, bytes32 indexed name, StarterClass indexed starterClass);


    modifier isOwner() {
        require(msg.sender == owner, "Caller is Not Player Owner!");
        _;
    }

    modifier isWarden() {
        require(msg.sender == world.warden(), "Caller is Not Warden!");
        _;
        
    }

    modifier starterPackIsAvailable() {
        require(!starterPackClaimed, "Starter Pack Already Claimed!");
        _;
    }

    


    bool public isSafe;   // if True, player cannot be attacked by others
    
    address public owner;
    
    bool private starterPackClaimed;
    
    uint8 public level;
    
    
    
    constructor(bytes32 _name) {
        owner = msg.sender; // 'msg.sender' is sender of current call, contract deployer for a constructor
        name = _name;
        starterPackClaimed = false; //Should be set to default anyways but feels better to explicitly set it
        emit PlayerCreated(owner, name);
    }
    
    
    function claimStarterPack(StarterClass starterClass) private starterPackIsAvailable {
        experience = world.getStarterExperience(starterClass);
        equipment = world.getStarterEquipment(starterClass);
        starterPackClaimed = true;
        emit PlayerClaimedStarterPack(owner, name, starterClass);
    }
    
    function receiveSkillExperience(Skill _skill, uint256 _xp) private isWarden {
        //This is duplicated and hella ugly, fix it!
        if (_skill == Skill.Strength) {
           experience.strength += _xp;
       } else if (_skill == Skill.Sorcery) {
           experience.sorcery += _xp;
       } else if (_skill == Skill.Archery) {
           experience.archery += _xp;
       } else if (_skill == Skill.Stamina) {
           experience.stamina += _xp;
       } else if (_skill == Skill.Life) {
           experience.life += _xp;
       } else if (_skill == Skill.Defense) {
           experience.defense += _xp;
       } else {
           revert ("Skill is Not Yet Supported!");
       }
       level = world.getPlayerLevel(experience);
    }
    
    function receiveItem()
}
