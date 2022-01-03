pragma solidity >=0.7.0 <0.9.0;

//SPDX-License-Identifier: UNLICENSED

import "https://github.com/Kroonjay/ChainScape-Solidity/blob/master/contracts/enums/EntityType.sol";
import "https://github.com/Kroonjay/ChainScape-Solidity/blob/master/contracts/enums/ItemTier.sol";

import "https://github.com/Kroonjay/ChainScape-Solidity/blob/master/contracts/Entity.sol";


contract Boss is Entity {

    ItemTier public tier;
    uint public seed;

    constructor(ItemTier _tier, uint _seed) Entity(WORLD.warden(), EntityType.Boss) {
        tier = _tier;
        seed = _seed;
    }

    


}