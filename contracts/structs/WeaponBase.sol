pragma solidity >=0.7.0 <0.9.0;

//SPDX-License-Identifier: UNLICENSED

import "../enums/DamageType.sol";
import "../enums/WeaponType.sol";
import "../enums/ItemTier.sol";
import "../enums/EquipmentSlot.sol";
import "../enums/Status.sol";

struct WeaponBase {
        uint256 seed;
        DamageType damageType;
        WeaponType weaponType;
        uint256 damage;
        uint8 attackSpeed;
        Status status; //Used to check if item exists in mapping
    }