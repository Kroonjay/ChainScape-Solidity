pragma solidity >=0.7.0 <0.9.0;

//SPDX-License-Identifier: UNLICENSED

import "../Item.sol";


struct PlayerState {
    uint damage;
    uint damageBlocked;
    Item[] itemRewards;
}