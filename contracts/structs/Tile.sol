pragma solidity >=0.7.0 <0.9.0;

//SPDX-License-Identifier: UNLICENSED

import "https://github.com/Kroonjay/ChainScape-Solidity/blob/master/contracts/Entity.sol";


struct TileEntity {
    Entity entity;
    bool hasMoved;
}


struct Tile {
    TileEntity[] entities;
    uint count;
    uint damage;
}