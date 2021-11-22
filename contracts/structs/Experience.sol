// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

struct Experience {
        uint256 strength; // Required to use Physical Weapons
        uint256 sorcery;  // Required to use Magical Weapons
        uint256 archery; // Required to use Projectile Weapons
        uint256 stamina;
        uint256 life;
        uint256 defense;
    }