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
        subFranchiserImplementation = new SubFranchiser(votingToken);
        franchiserImplementation = new Franchiser(
            votingToken,
            subFranchiserImplementation
        );
    }

    function getSalt(address owner, address beneficiary)
        private
        pure
        returns (bytes32)
    {
        return keccak256(abi.encodePacked(owner, beneficiary));
    }

    /// @inheritdoc IFranchiserFactory
    function getFranchiser(address owner, address beneficiary)
        public
        view
        returns (Franchiser)
    {
        return
            Franchiser(
                address(franchiserImplementation).predictDeterministicAddress(
                    getSalt(owner, beneficiary),
                    address(this)
                )
            );
    }

    /// @inheritdoc IFranchiserFactory
    function fund(address beneficiary, uint256 amount)
        public
        returns (Franchiser franchiser)
    {
        franchiser = getFranchiser(msg.sender, beneficiary);
        // deploy a new contract if necessary
        if (!address(franchiser).isContract()) {
            franchiser = Franchiser(
                address(franchiserImplementation).cloneDeterministic(
                    getSalt(msg.sender, beneficiary)
                )
            );
            franchiser.initialize(address(this), beneficiary);
            emit NewFranchiser(msg.sender, beneficiary, franchiser);
        }

        ERC20(address(votingToken)).safeTransferFrom(
            msg.sender,
            address(franchiser),
            amount
        );
    }

    /// @inheritdoc IFranchiserFactory
    function recall(address beneficiary, address to) external {
        Franchiser franchiser = getFranchiser(msg.sender, beneficiary);
        if (address(franchiser).isContract()) franchiser.recall(to);
    }

    /// @inheritdoc IFranchiserFactory
    function permitAndFund(
        address beneficiary,
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
        return fund(beneficiary, amount);
    }
}
