// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.15;

import {Test} from "forge-std/Test.sol";
import {ERC20, ERC20Permit, ERC20Votes} from "openzeppelin-contracts/contracts/token/ERC20/extensions/ERC20Votes.sol";

import {Franchiser} from "../src/Franchiser.sol";
import {IFranchiserEvents} from "../src/interfaces/IFranchiserEvents.sol";

contract VotesTest is ERC20Votes {
    constructor() ERC20("Test", "TEST") ERC20Permit("Test") {}

    function mint(address to, uint256 amount) external {
        _mint(to, amount);
    }
}

contract FranchiserTest is Test, IFranchiserEvents {
    address private constant alice = 0xaAaAaAaaAaAaAaaAaAAAAAAAAaaaAaAaAaaAaaAa;
    address private constant bob = 0xbBbBBBBbbBBBbbbBbbBbbbbBBbBbbbbBbBbbBBbB;

    VotesTest private votes;
    Franchiser private franchiser;

    function setUp() public {
        votes = new VotesTest();
        franchiser = new Franchiser(alice);
        vm.startPrank(alice);
    }

    function testFailChangeBeneficiary() public {
        vm.prank(bob);
        franchiser.changeBeneficiary(bob);
    }

    function testChangeBeneficiary() public {
        assertEq(franchiser.beneficiary(), address(0));

        vm.expectEmit(true, true, false, true, address(franchiser));
        emit BeneficiaryChanged(address(0), bob);

        franchiser.changeBeneficiary(bob);
        assertEq(franchiser.beneficiary(), bob);
    }
}
