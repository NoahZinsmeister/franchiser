// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.15;

import {IFranchiserFactory} from "./interfaces/FranchiserFactory/IFranchiserFactory.sol";
import {FranchiserImmutableState} from "./base/FranchiserImmutableState.sol";
import {Address} from "openzeppelin-contracts/contracts/utils/Address.sol";
import {Clones} from "openzeppelin-contracts/contracts/proxy/Clones.sol";
import {SafeTransferLib, ERC20} from "solmate/utils/SafeTransferLib.sol";
import {IVotingToken} from "./interfaces/IVotingToken.sol";
import {Franchiser} from "./Franchiser.sol";
import {SubFranchiser} from "./SubFranchiser.sol";

contract FranchiserFactory is IFranchiserFactory, FranchiserImmutableState {
    using Address for address;
    using Clones for address;
    using SafeTransferLib for ERC20;

    /// @inheritdoc IFranchiserFactory
    Franchiser public immutable franchiserImplementation;
    /// @inheritdoc IFranchiserFactory
    SubFranchiser public immutable subFranchiserImplementation;

    constructor(IVotingToken votingToken)
        FranchiserImmutableState(votingToken)
    {
        franchiserImplementation = new Franchiser(
            votingToken,
            subFranchiserImplementation = new SubFranchiser(votingToken)
        );
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
        // deploy a new contract if necessary
        if (!address(franchiser).isContract()) {
            franchiser = Franchiser(
                address(franchiserImplementation).cloneDeterministic(
                    getSalt(msg.sender, delegatee)
                )
            );
            franchiser.initialize(address(this), delegatee);
            emit NewFranchiser(msg.sender, delegatee, franchiser);
        }

        ERC20(address(votingToken)).safeTransferFrom(
            msg.sender,
            address(franchiser),
            amount
        );
    }

    /// @inheritdoc IFranchiserFactory
    function recall(address delegatee, address to) external {
        Franchiser franchiser = getFranchiser(msg.sender, delegatee);
        if (address(franchiser).isContract()) franchiser.recall(to);
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
        return fund(delegatee, amount);
    }
}
