//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {SJ741} from "./SJ741.sol";

contract Emeralds is SJ741 {
    constructor() SJ741("SJ741 Emeralds", "EMERALD", "https://raw.githubusercontent.com/SerecThunderson/assets/main/emeralds/metadata/") {}
}