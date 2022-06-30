// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.15;

import {IFranchiser} from "./interfaces/Franchiser/IFranchiser.sol";
import {FranchiserImmutableState} from "./base/FranchiserImmutableState.sol";
import {Owned} from "solmate/auth/Owned.sol";
import {EnumerableSet} from "openzeppelin-contracts/contracts/utils/structs/EnumerableSet.sol";
import {Address} from "openzeppelin-contracts/contracts/utils/Address.sol";
import {Clones} from "openzeppelin-contracts/contracts/proxy/Clones.sol";
import {SafeTransferLib, ERC20} from "solmate/utils/SafeTransferLib.sol";
import {IVotingToken} from "./interfaces/IVotingToken.sol";

contract Franchiser is IFranchiser, FranchiserImmutableState, Owned {
    using EnumerableSet for EnumerableSet.AddressSet;
    using Address for address;
    using Clones for address;
    using SafeTransferLib for ERC20;

    /// @inheritdoc IFranchiser
    Franchiser public immutable franchiserImplementation;

    /// @inheritdoc IFranchiser
    address public delegatee;
    /// @inheritdoc IFranchiser
    uint96 public maximumSubDelegatees;

    EnumerableSet.AddressSet private _subDelegatees;

    /// @inheritdoc IFranchiser
    function subDelegatees() public view returns (address[] memory) {
        return _subDelegatees.values();
    }

    /// @dev Reverts if called by any account other than the `delegatee`.
    modifier onlyDelegatee() {
        if (msg.sender != delegatee) revert NotDelegatee(msg.sender, delegatee);
        _;
    }

    constructor(IVotingToken votingToken)
        FranchiserImmutableState(votingToken)
        Owned(address(0))
    {
        franchiserImplementation = Franchiser(address(this));
        // this borks the implementation contract as desired,
        // new instances should be cloned.
        delegatee = address(1);
    }

    /// @inheritdoc IFranchiser
    function initialize(
        address owner_,
        address delegatee_,
        uint96 maximumSubDelegatees_
    ) external {
        // the following two conditions, along with the fact
        // that delegatee is only set below (outside of the constructor),
        // ensures that initialize can only be called once in clones
        if (delegatee_ == address(0)) revert NoDelegatee();
        if (delegatee != address(0)) revert AlreadyInitialized();
        owner = owner_;
        delegatee = delegatee_;
        maximumSubDelegatees = maximumSubDelegatees_;
        votingToken.delegate(delegatee_);
        emit Initialized(owner_, delegatee_, maximumSubDelegatees_);
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
    function recall(address to) public {
        uint256 numberOfSubDelegatees = _subDelegatees.length();
        unchecked {
            for (uint256 i; i < numberOfSubDelegatees; i++)
                // must use 0 not i, as ordering isn't consistent across removals
                _unSubDelegate(_subDelegatees.at(0), true);
        }

        ERC20(address(votingToken)).safeTransfer(
            to,
            votingToken.balanceOf(address(this))
        );
    }
}
