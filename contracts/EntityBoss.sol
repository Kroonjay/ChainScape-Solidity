pragma solidity >=0.7.0 <0.9.0;

//SPDX-License-Identifier: UNLICENSED

import "./enums/EntityType.sol";
import "./enums/ItemTier.sol";

import "./Entity.sol";


contract Boss is Entity {

    constructor(string _name, address _owner) Entity(_name, _owner, EntityType.Boss) {
        
    }
}