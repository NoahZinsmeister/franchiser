// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.15;

import {Script} from "forge-std/Script.sol";
import {IVotingToken} from "../src/interfaces/IVotingToken.sol";
import {IVotingToken} from "../src/FranchiserFactory.sol";
import {FranchiserFactory} from "../src/FranchiserFactory.sol";
import {FranchiserLens} from "../src/FranchiserLens.sol";

contract Deploy is Script {
    IVotingToken public constant UNI =
        IVotingToken(0x1f9840a85d5aF5bf1D1762F925BDADdC4201F984);

    function run() public {
        vm.startBroadcast();
        FranchiserFactory franchiserFactory = new FranchiserFactory(UNI);
        new FranchiserLens(UNI, franchiserFactory);
        vm.stopBroadcast();
    }
}
