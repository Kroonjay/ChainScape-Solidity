pragma solidity >=0.7.0 <0.9.0;

//SPDX-License-Identifier: UNLICENSED

import "https://github.com/Kroonjay/ChainScape-Solidity/blob/master/contracts/Item.sol";


struct PlayerState {
    uint damage;
    uint damageBlocked;
    Item[] itemRewards;
}