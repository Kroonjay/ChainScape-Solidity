// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

import "./Entity.sol";

import "./enums/EntityType.sol";
import "./enums/Objective.sol";
import "./enums/Skill.sol";



contract Player is Entity {

    Objective public objective;


    event ChangedObjective(Objective oldObjective, Objective newObjective);


    constructor(address _owner) Entity(_owner, EntityType.Player) {

    }

    function setObjective(Objective _newObjective) external isOwner {
        emit ChangedObjective(objective, _newObjective);(objective, _newObjective);
        objective = _newObjective;
    }

    function receiveExperience(Skill _skill, uint256 _experience) external isWarden {
        uint skillExperience = experience[_skill] + _experience;
        experience[_skill] = skillExperience;
        emit GainedExperience(_skill, _experience);
    }
}