// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.15;

import {Vm} from "forge-std/Vm.sol";
import {ERC20, ERC20Permit, ERC20Votes} from "openzeppelin-contracts/contracts/token/ERC20/extensions/ERC20Votes.sol";
import {SigUtils} from "./SigUtils.sol";

contract VotingTokenConcrete is ERC20Votes {
    constructor() ERC20("Test", "TEST") ERC20Permit("Test") {}

    function mint(address to, uint256 amount) external {
        _mint(to, amount);
    }

    function getPermitSignature(
        Vm vm,
        uint256 ownerPrivateKey,
        address spender,
        uint256 value
    )
        external
        returns (
            address owner,
            uint256 deadline,
            uint8 v,
            bytes32 r,
            bytes32 s
        )
    {
        bytes32 digest = SigUtils.getTypedDataHash(
            this.DOMAIN_SEPARATOR(),
            owner = vm.addr(ownerPrivateKey),
            spender,
            value,
            0,
            deadline = type(uint256).max
        );
        (v, r, s) = vm.sign(ownerPrivateKey, digest);
    }
}
