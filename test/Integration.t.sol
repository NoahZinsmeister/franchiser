// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.15;

import {Test} from "forge-std/Test.sol";
import {IVotingToken} from "../src/interfaces/IVotingToken.sol";
import {FranchiserFactory} from "../src/FranchiserFactory.sol";
import {Utils} from "./Utils.sol";
import {ERC20VotesComp} from "openzeppelin-contracts/contracts/token/ERC20/extensions/ERC20VotesComp.sol";
import {IERC20} from "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";

interface ITimelock {
    function delay() external view returns (uint256);
}

interface IGovernorBravo {
    function quorumVotes() external view returns (uint256);

    function votingDelay() external view returns (uint256);

    function votingPeriod() external view returns (uint256);

    function propose(
        address[] memory targets,
        uint256[] memory values,
        string[] memory signatures,
        bytes[] memory calldatas,
        string memory description
    ) external returns (uint256);

    function castVote(uint256 proposalId, uint8 support) external;

    function queue(uint256 proposalId) external;

    function execute(uint256 proposalId) external;
}

contract IntegrationTest is Test {
    IVotingToken private constant UNI =
        IVotingToken(0x1f9840a85d5aF5bf1D1762F925BDADdC4201F984);
    ITimelock private constant TIMELOCK =
        ITimelock(0x1a9C8182C09F50C8318d769245beA52c32BE35BC);
    IGovernorBravo private constant GOVERNOR_BRAVO =
        IGovernorBravo(0x408ED6354d4973f66138C91495F2f2FCbd8724C3);

    FranchiserFactory private franchiserFactory;

    function setUp() public {
        vm.startPrank(address(0));
        franchiserFactory = new FranchiserFactory(UNI);
        // fund the timelock with 1 ETH to send txs
        (bool success, ) = address(TIMELOCK).call{value: 1e18}("");
        assert(success);
        vm.stopPrank();
    }

    function testEndToEnd() public {
        uint256 quorumVotes = GOVERNOR_BRAVO.quorumVotes();

        vm.startPrank(address(TIMELOCK));
        UNI.approve(address(franchiserFactory), quorumVotes);
        franchiserFactory.fund(Utils.alice, quorumVotes);
        vm.stopPrank();

        // encode a call to send 1 wei of UNI to alice
        address[] memory targets = new address[](1);
        uint256[] memory values = new uint256[](1);
        string[] memory signatures = new string[](1);
        bytes[] memory calldatas = new bytes[](1);
        targets[0] = address(UNI);
        calldatas[0] = abi.encodeCall(IERC20.transfer, (Utils.alice, 1));

        uint256 aliceBalance = UNI.balanceOf(Utils.alice);

        // advance the block number so that alice's votes are locked in
        vm.roll(block.number + 1);
        vm.prank(Utils.alice);
        uint256 proposalId = GOVERNOR_BRAVO.propose(
            targets,
            values,
            signatures,
            calldatas,
            ""
        );

        // advance the block number until voting starts
        vm.roll(block.number + GOVERNOR_BRAVO.votingDelay() + 1);
        vm.prank(Utils.alice);
        GOVERNOR_BRAVO.castVote(proposalId, 1);

        // advance the block number until voting ends
        vm.roll(block.number + GOVERNOR_BRAVO.votingPeriod());
        GOVERNOR_BRAVO.queue(proposalId);

        // advance the block timestamp until the proposal can be executed
        vm.warp(block.timestamp + TIMELOCK.delay());
        GOVERNOR_BRAVO.execute(proposalId);

        assertEq(UNI.balanceOf(Utils.alice), aliceBalance + 1);
    }
}
