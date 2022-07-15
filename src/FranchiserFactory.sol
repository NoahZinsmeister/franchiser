// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.15;

import {IFranchiserFactory} from "./interfaces/FranchiserFactory/IFranchiserFactory.sol";
import {FranchiserImmutableState} from "./base/FranchiserImmutableState.sol";
import {Address} from "openzeppelin-contracts/contracts/utils/Address.sol";
import {Clones} from "openzeppelin-contracts/contracts/proxy/Clones.sol";
import {SafeTransferLib, ERC20} from "solmate/utils/SafeTransferLib.sol";
import {IVotingToken} from "./interfaces/IVotingToken.sol";
import {Franchiser} from "./Franchiser.sol";

contract FranchiserFactory is IFranchiserFactory, FranchiserImmutableState {
    using Address for address;
    using Clones for address;
    using SafeTransferLib for ERC20;

    /// @inheritdoc IFranchiserFactory
    uint96 public constant INITIAL_MAXIMUM_SUBDELEGATEES = 2**3; // 8

    /// @inheritdoc IFranchiserFactory
    Franchiser public immutable franchiserImplementation;

    constructor(IVotingToken votingToken_)
        FranchiserImmutableState(votingToken_)
    {
        franchiserImplementation = new Franchiser(votingToken_);
    }

    function getSalt(address owner, address delegatee)
        private
        pure
        returns (bytes32)
    {
        return keccak256(abi.encodePacked(owner, delegatee));
    }

    /// @inheritdoc IFranchiserFactory
    function getFranchiser(address owner, address delegatee)
        public
        view
        returns (Franchiser)
    {
        return
            Franchiser(
                address(franchiserImplementation).predictDeterministicAddress(
                    getSalt(owner, delegatee),
                    address(this)
                )
            );
    }

    /// @inheritdoc IFranchiserFactory
    function fund(address delegatee, uint256 amount)
        public
        returns (Franchiser franchiser)
    {
        franchiser = getFranchiser(msg.sender, delegatee);
        if (!address(franchiser).isContract()) {
            // deploy a new contract if necessary
            address(franchiserImplementation).cloneDeterministic(
                getSalt(msg.sender, delegatee)
            );
            franchiser.initialize(
                msg.sender,
                delegatee,
                INITIAL_MAXIMUM_SUBDELEGATEES
            );
        }
        ERC20(address(votingToken)).safeTransferFrom(
            msg.sender,
            address(franchiser),
            amount
        );
    }

    /// @inheritdoc IFranchiserFactory
    function fundMany(address[] calldata delegatees, uint256[] calldata amounts)
        external
        returns (Franchiser[] memory franchisers)
    {
        if (delegatees.length != amounts.length)
            revert ArrayLengthMismatch(delegatees.length, amounts.length);

        franchisers = new Franchiser[](delegatees.length);
        unchecked {
            for (uint256 i = 0; i < delegatees.length; i++)
                franchisers[i] = fund(delegatees[i], amounts[i]);
        }
    }

    /// @inheritdoc IFranchiserFactory
    function recall(address delegatee, address to) public {
        Franchiser franchiser = getFranchiser(msg.sender, delegatee);
        if (address(franchiser).isContract()) franchiser.recall(to);
    }

    /// @inheritdoc IFranchiserFactory
    function recallMany(address[] calldata delegatees, address[] calldata tos)
        external
    {
        if (delegatees.length != tos.length)
            revert ArrayLengthMismatch(delegatees.length, tos.length);

        unchecked {
            for (uint256 i = 0; i < delegatees.length; i++)
                recall(delegatees[i], tos[i]);
        }
    }

    function permit(
        uint256 amount,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) private {
        // this check ensures that if the permit is front-run,
        // the call does not fail
        if (votingToken.allowance(msg.sender, address(this)) < amount)
            votingToken.permit(
                msg.sender,
                address(this),
                amount,
                deadline,
                v,
                r,
                s
            );
    }

    /// @inheritdoc IFranchiserFactory
    function permitAndFund(
        address delegatee,
        uint256 amount,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (Franchiser) {
        permit(amount, deadline, v, r, s);
        return fund(delegatee, amount);
    }

    /// @inheritdoc IFranchiserFactory
    function permitAndFundMany(
        address[] calldata delegatees,
        uint256[] calldata amounts,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (Franchiser[] memory franchisers) {
        if (delegatees.length != amounts.length)
            revert ArrayLengthMismatch(delegatees.length, amounts.length);

        uint256 amount = 0;
        for (uint256 i = 0; i < delegatees.length; i++) amount += amounts[i];
        permit(amount, deadline, v, r, s);
        franchisers = new Franchiser[](delegatees.length);
        unchecked {
            for (uint256 i = 0; i < delegatees.length; i++)
                franchisers[i] = fund(delegatees[i], amounts[i]);
        }
    }
}
