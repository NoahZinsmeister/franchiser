// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.15;

import {IFranchiser} from "./interfaces/Franchiser/IFranchiser.sol";
import {OwnedDelegator} from "./base/OwnedDelegator.sol";
import {EnumerableSet} from "openzeppelin-contracts/contracts/utils/structs/EnumerableSet.sol";
import {Address} from "openzeppelin-contracts/contracts/utils/Address.sol";
import {Clones} from "openzeppelin-contracts/contracts/proxy/Clones.sol";
import {SafeTransferLib, ERC20} from "solmate/utils/SafeTransferLib.sol";
import {IVotingToken} from "./interfaces/IVotingToken.sol";

contract Franchiser is IFranchiser, OwnedDelegator {
    using EnumerableSet for EnumerableSet.AddressSet;
    using Address for address;
    using Clones for address;
    using SafeTransferLib for ERC20;

    /// @inheritdoc IFranchiser
    Franchiser public immutable franchiserImplementation;

    /// @inheritdoc IFranchiser
    uint256 public maximumSubDelegatees;

    EnumerableSet.AddressSet private _subDelegatees;

    /// @inheritdoc IFranchiser
    function subDelegatees() public view returns (address[] memory) {
        return _subDelegatees.values();
    }

    constructor(IVotingToken votingToken) OwnedDelegator(votingToken) {
        franchiserImplementation = Franchiser(address(this));
    }

    /// @inheritdoc IFranchiser
    function initialize(
        address owner,
        address delegatee,
        uint256 maximumSubDelegatees_
    ) external {
        OwnedDelegator.initialize(owner, delegatee);
        maximumSubDelegatees = maximumSubDelegatees_;
        emit MaximumSubDelegateesSet(maximumSubDelegatees_);
    }

    function getSalt(address subDelegatee) private pure returns (bytes32) {
        return bytes20(subDelegatee);
    }

    /// @inheritdoc IFranchiser
    function getFranchiser(address subDelegatee)
        public
        view
        returns (Franchiser)
    {
        return
            Franchiser(
                address(franchiserImplementation).predictDeterministicAddress(
                    getSalt(subDelegatee),
                    address(this)
                )
            );
    }

    /// @inheritdoc IFranchiser
    function subDelegate(address subDelegatee, uint256 amount)
        external
        onlyDelegatee
        returns (Franchiser franchiser)
    {
        if (_subDelegatees.length() == maximumSubDelegatees)
            revert CannotExceedMaximumSubDelegatees(maximumSubDelegatees);
        if (_subDelegatees.contains(subDelegatee))
            revert SubDelegateeAlreadyActive(subDelegatee);

        franchiser = getFranchiser(subDelegatee);
        // deploy a new contract if necessary
        if (!address(franchiser).isContract()) {
            franchiser = Franchiser(
                address(franchiserImplementation).cloneDeterministic(
                    getSalt(subDelegatee)
                )
            );
            franchiser.initialize(
                address(this),
                subDelegatee,
                maximumSubDelegatees / 2
            );
        }

        ERC20(address(votingToken)).safeTransfer(address(franchiser), amount);
        _subDelegatees.add(subDelegatee);
        emit SubDelegateeActivated(subDelegatee, franchiser);
    }

    /// @inheritdoc IFranchiser
    function unSubDelegate(address subDelegatee) external onlyDelegatee {
        _unSubDelegate(subDelegatee, false);
    }

    /// @dev Must only set assumeExistence to true when the subDelegatee exists
    ///      and is already a subDelegatee. This saves gas in recall.
    function _unSubDelegate(address subDelegatee, bool assumeExistence)
        private
    {
        Franchiser franchiser = getFranchiser(subDelegatee);
        if (assumeExistence || address(franchiser).isContract())
            franchiser.recall(address(this));
        if (assumeExistence || _subDelegatees.contains(subDelegatee)) {
            _subDelegatees.remove(subDelegatee);
            emit SubDelegateeDeactivated(subDelegatee, franchiser);
        }
    }

    /// @inheritdoc IFranchiser
    function recall(address to) public override(IFranchiser, OwnedDelegator) {
        // very important that we copy into memory to avoid bugs due to ordering
        address[] memory subDelegatees_ = subDelegatees();
        unchecked {
            for (uint256 i; i < subDelegatees_.length; i++)
                _unSubDelegate(subDelegatees_[i], true);
        }
        OwnedDelegator.recall(to);
    }
}
