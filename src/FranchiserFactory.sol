// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.15;

import {IFranchiserFactory} from "./interfaces/FranchiserFactory/IFranchiserFactory.sol";
import {FranchiserImmutableState} from "./base/FranchiserImmutableState.sol";
import {Clones} from "openzeppelin-contracts/contracts/proxy/Clones.sol";
import {SafeTransferLib, ERC20} from "solmate/utils/SafeTransferLib.sol";
import {IVotingToken} from "./interfaces/IVotingToken.sol";
import {Franchiser} from "./Franchiser.sol";

contract FranchiserFactory is IFranchiserFactory, FranchiserImmutableState {
    using Clones for address;
    using SafeTransferLib for ERC20;

    /// @inheritdoc IFranchiserFactory
    Franchiser public immutable franchiserImplementation;

    mapping(address => mapping(address => Franchiser)) private _franchisers;

    constructor(IVotingToken votingToken)
        FranchiserImmutableState(votingToken)
    {
        // because this contract is the owner of the implementation contract,
        // we can safely skip initialization, as it is impossible to trigger
        // a call to initialize the implementation.
        franchiserImplementation = new Franchiser(votingToken);
    }

    function getSalt(address owner, address beneficiary)
        private
        pure
        returns (bytes32)
    {
        return keccak256(abi.encodePacked(owner, beneficiary));
    }

    /// @inheritdoc IFranchiserFactory
    function franchisers(address owner, address beneficiary)
        external
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
        franchiser = _franchisers[msg.sender][beneficiary];
        // deploy a new contract if necessary
        if (address(franchiser) == address(0)) {
            franchiser = Franchiser(
                address(franchiserImplementation).cloneDeterministic(
                    getSalt(msg.sender, beneficiary)
                )
            );
            franchiser.initialize(beneficiary);
            _franchisers[msg.sender][beneficiary] = franchiser;
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
        Franchiser franchiser = _franchisers[msg.sender][beneficiary];
        if (address(franchiser) != address(0)) franchiser.recall(to);
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
