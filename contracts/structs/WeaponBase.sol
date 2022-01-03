pragma solidity >=0.7.0 <0.9.0;

//SPDX-License-Identifier: UNLICENSED

import "https://github.com/Kroonjay/ChainScape-Solidity/blob/master/contracts/enums/DamageType.sol";
import "https://github.com/Kroonjay/ChainScape-Solidity/blob/master/contracts/enums/WeaponType.sol";
import "https://github.com/Kroonjay/ChainScape-Solidity/blob/master/contracts/enums/ItemTier.sol";
import "https://github.com/Kroonjay/ChainScape-Solidity/blob/master/contracts/enums/EquipmentSlot.sol";
import "https://github.com/Kroonjay/ChainScape-Solidity/blob/master/contracts/enums/Status.sol";

struct WeaponBase {
        uint256 seed;
        ItemTier tier;
        DamageType damageType;
        WeaponType weaponType;
        uint256 damage;
        uint8 attackSpeed;
        Status status; //Used to check if item exists in mapping
    }