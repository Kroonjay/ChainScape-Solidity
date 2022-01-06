pragma solidity >=0.7.0 <0.9.0;

//SPDX-License-Identifier: UNLICENSED

import "./World.sol";

import "./enums/EquipmentSlot.sol";
import "./enums/ItemTier.sol";

contract Item {
    
    World constant public WORLD = World(0x992DA8eC2af8ec58E89E3293Fb3aaC8ebD7602B8);
    
    address public owner;
    
    EquipmentSlot public slot;
    ItemTier public tier;

    uint public seed;

    modifier isWarden() {
        //Ensure only the active Warden is able to Create Items
        require(msg.sender == WORLD.warden(), "Caller is Not Warden!");
        _;
    }

    modifier isZima() {
        require(msg.sender == WORLD.owner(), "Caller is Not Zima!");
        _;
    }

    modifier isOwner() {
        require(msg.sender == owner, "Caller is Not Item Owner!");
        _;
    }
    
    constructor(EquipmentSlot _slot, ItemTier _tier, uint _seed, address _owner) isWarden {
        slot = _slot;
        tier = _tier;
        owner = _owner;
        seed = _seed;
    }


}