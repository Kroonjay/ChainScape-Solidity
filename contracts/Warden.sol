pragma solidity >=0.7.0 <0.9.0;

//SPDX-License-Identifier: UNLICENSED

import "./World.sol";

contract Warden {
    
    event GameTick(uint256 indexed tickNumber, uint256 indexed tickBlockHeight);
    
    address public worldAddress;
    World public world = World(worldAddress);
    
    address public owner;
    uint256 public tickBlockHeight;

    uint256 public tick;
    
    uint256 private tickSeed;
    uint256 private itemNonce; //Incremented each time a unique Item is created.  Else all items in a given tick would be identical
    
    
    modifier isOwner() {
        // If the first argument of 'require' evaluates to 'false', execution terminates and all
        // changes to the state and to Ether balances are reverted.
        // This used to consume all gas in old EVM versions, but not anymore.
        // It is often a good idea to use 'require' to check if functions are called correctly.
        // As a second argument, you can also provide an explanation about what went wrong.
        require(msg.sender == owner, "Caller is not owner");
        _;
    }
    
    modifier isNextTick() {
        //Checks current block height against previous tick's height + number of blocks per tick defined in World contract.  
        uint256 nextTickHeight = tickBlockHeight + world.blocksPerTick();
        require(block.number >= nextTickHeight, "Not Ready to Advance Tick!");
        _;
    }

   
    //To be Called by World Contract
    constructor(uint256 _tickSeed) {
        owner = msg.sender;
        worldAddress = owner; //TODO Hard-Code World Address
        tick = 1; //Increment our tick
        tickBlockHeight = block.number; //Set tickBlockHeight to current block
        tickSeed = _tickSeed;
    }
    
    function setTick(uint256 _tickSeed) external isOwner isNextTick {
        tickBlockHeight = block.number;
        tickSeed = _tickSeed;
        tick++;
        emit GameTick(tick, tickBlockHeight);
    }
    
}