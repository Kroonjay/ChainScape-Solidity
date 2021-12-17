pragma solidity >=0.7.0 <0.9.0;

//SPDX-License-Identifier: UNLICENSED

import "../Entity.sol";


struct TileEntity {
    Entity entity;
    bool hasMoved;
}


struct Tile {
    TileEntity[] entities;
    uint count;
    uint damage;
}