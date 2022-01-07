// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

import "../Weapon.sol";


struct Equipment {
        address helmet;
        address armor;
        Weapon weapon;
        address blessing;
}