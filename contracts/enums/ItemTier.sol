
// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

enum ItemTier {Undefined, Starter, Normal, Rare, Exotic} //Undefined ensures all valid values are greater than 0.  All Tiers < Exotic are considered "Common"