// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

import "./Entity.sol";

import "./enums/EntityType.sol";
import "./enums/Objective.sol";
import "./enums/Skill.sol";



contract Player is Entity {

    Objective public objective;


    event ChangedObjective(Objective oldObjective, Objective newObjective);
    event GainedExperience(Skill skill, uint experience);


    constructor(string _name, address _owner) Entity(_name, _owner, EntityType.Player) {
        name = _name;
        owner = _owner;
    }

    function setObjective(Objective _newObjective) external isOwner {
        emit SetObjective(objective, _newObjective);
        objective = _newObjective;
    }

    function receiveExperience(Skill _skill, uint256 _experience) external isWarden {
        uint skillExperience = experience[_skill] + _experience;
        experience[_skill] = skillExperience;
        emit GainedExperience(_skill, _experience);
    }

    function getHash() external view returns (bytes32) {
        return keccak256(abi.encodePacked(_player.owner, _player.equipment, _player.experience, _player.inventory));
    }
}