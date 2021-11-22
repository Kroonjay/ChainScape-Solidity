pragma solidity >=0.7.0 <0.9.0;

//SPDX-License-Identifier: UNLICENSED

import "./World.sol";

import "./enums/EquipmentSlot.sol";
import "./enums/ItemTier.sol";

contract Item {
    
    address public worldAddress;
    
    address public owner;
    
    World world = World(worldAddress);
    
    EquipmentSlot public slot;
    ItemTier public tier;
    
    modifier isWarden() {
        //Ensure only the active Warden is able to Create Items
        require(msg.sender == world.warden(), "Caller is Not Warden!");
        _;
        
    }
    
    modifier isUnidentified() {
        require(!isIdentified, "Item has Already been Identified!");
        _;
    }
    
    
    constructor(EquipmentSlot _slot, ItemTier _tier) isWarden {
        slot = _slot;
        tier = _tier;
        owner = msg.sender;
    }
}