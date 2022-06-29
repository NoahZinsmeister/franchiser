// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.15;

import {IFranchiser} from "./interfaces/Franchiser/IFranchiser.sol";
import {OwnedDelegator} from "./base/OwnedDelegator.sol";
import {EnumerableSet} from "openzeppelin-contracts/contracts/utils/structs/EnumerableSet.sol";
import {Address} from "openzeppelin-contracts/contracts/utils/Address.sol";
import {Clones} from "openzeppelin-contracts/contracts/proxy/Clones.sol";
import {SafeTransferLib, ERC20} from "solmate/utils/SafeTransferLib.sol";
import {SubFranchiser} from "./SubFranchiser.sol";
import {IVotingToken} from "./interfaces/IVotingToken.sol";

contract Franchiser is IFranchiser, OwnedDelegator {
    using EnumerableSet for EnumerableSet.AddressSet;
    using Address for address;
    using Clones for address;
    using SafeTransferLib for ERC20;

    /// @inheritdoc IFranchiser
    uint256 public constant maximumActiveSubDelegatees = 10;

    /// @inheritdoc IFranchiser
    SubFranchiser public immutable subFranchiserImplementation;

    EnumerableSet.AddressSet private _activeSubDelegatees;

    constructor(
        IVotingToken votingToken,
        SubFranchiser subFranchiserImplementation_
    ) OwnedDelegator(votingToken) {
        subFranchiserImplementation = subFranchiserImplementation_;
    }

    /// @inheritdoc IFranchiser
    function activeSubDelegatees() external view returns (address[] memory) {
        return _activeSubDelegatees.values();
    }

    function getSalt(address subDelegatee) private pure returns (bytes32) {
        return bytes20(subDelegatee);
    }

    /// @inheritdoc IFranchiser
    function getSubFranchiser(address subDelegatee)
        public
        view
        returns (SubFranchiser)
    {
        return
            SubFranchiser(
                address(subFranchiserImplementation)
                    .predictDeterministicAddress(
                        getSalt(subDelegatee),
                        address(this)
                    )
            );
    }

    /// @inheritdoc IFranchiser
    function subDelegate(uint256 amount, address subDelegatee)
        external
        onlyDelegatee
    {
        if (_activeSubDelegatees.length() == maximumActiveSubDelegatees)
            revert CannotExceedActiveSubDelegateesMaximum(
                maximumActiveSubDelegatees
            );
        if (_activeSubDelegatees.contains(subDelegatee))
            revert SubDelegateeAlreadyActive(subDelegatee);

        SubFranchiser subFranchiser = getSubFranchiser(subDelegatee);
        // deploy a new contract if necessary
        if (!address(subFranchiser).isContract()) {
            subFranchiser = SubFranchiser(
                address(subFranchiserImplementation).cloneDeterministic(
                    getSalt(subDelegatee)
                )
            );
            subFranchiser.initialize(address(this), subDelegatee);
        }

        ERC20(address(votingToken)).safeTransfer(
            address(subFranchiser),
            amount
        );
        _activeSubDelegatees.add(subDelegatee);
        emit SubDelegateeActivated(subDelegatee, subFranchiser);
    }

    /// @inheritdoc IFranchiser
    function unSubDelegate(address subDelegatee) external onlyDelegatee {
        if (!_activeSubDelegatees.contains(subDelegatee))
            revert SubDelegateeNotActive(subDelegatee);
        _unSubDelegate(subDelegatee);
    }

    function _unSubDelegate(address subDelegatee) private {
        SubFranchiser subFranchiser = getSubFranchiser(subDelegatee);
        subFranchiser.recall(address(this));
        _activeSubDelegatees.remove(subDelegatee);
        emit SubDelegateeDeactivated(subDelegatee, subFranchiser);
    }

    /// @inheritdoc IFranchiser
    function recall(address to) public override(IFranchiser, OwnedDelegator) {
        unchecked {
            for (uint256 i; i < _activeSubDelegatees.length(); i++) {
                address subDelegatee = _activeSubDelegatees.at(i);
                _unSubDelegate(subDelegatee);
            }
        }
        OwnedDelegator.recall(to);
    }
}
