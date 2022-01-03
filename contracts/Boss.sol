pragma solidity >=0.7.0 <0.9.0;

//SPDX-License-Identifier: UNLICENSED

import "./enums/EntityType.sol";
import "./enums/ItemTier.sol";

import "./Entity.sol";


contract Boss is Entity {

    ItemTier public tier;
    uint public seed;

    constructor(ItemTier _tier, uint _seed) Entity(WORLD.warden(), EntityType.Boss) {
        tier = _tier;
        seed = _seed;
    }

    


}