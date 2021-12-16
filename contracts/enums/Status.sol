pragma solidity >=0.7.0 <0.9.0;

//SPDX-License-Identifier: UNLICENSED

enum Status { New, Open, Active, Complete, Closed, Disabled} //Not totally sure how we'll use this beyond checking for existance in mappingss

enum Reason { Undefined, BossDied, OnePlayerRemaining, ReachedMaxTick, AdminCancelled }