// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.15;

import {IFranchiser} from "./interfaces/IFranchiser.sol";
import {Ownable} from "openzeppelin-contracts/contracts/access/Ownable.sol";
import {IVotingToken} from "./interfaces/IVotingToken.sol";
import {SafeTransferLib, ERC20} from "solmate/utils/SafeTransferLib.sol";

contract Franchiser is IFranchiser, Ownable {
    using SafeTransferLib for ERC20;

    /// @inheritdoc IFranchiser
    IVotingToken public immutable votingToken;

    /// @inheritdoc IFranchiser
    address public beneficiary;

    /**
     * @dev Reverts if called by any account other than the `beneficiary`.
     */
    modifier onlyBeneficiary() {
        if (msg.sender != beneficiary)
            revert NotBeneficiary(msg.sender, beneficiary);
        _;
    }

    constructor(address owner, IVotingToken votingToken_) {
        transferOwnership(owner);
        votingToken = votingToken_;
    }

    /// @inheritdoc IFranchiser
    function changeBeneficiary(address newBeneficiary) external onlyOwner {
        address previousBeneficiary = beneficiary;
        beneficiary = newBeneficiary;
        emit BeneficiaryChanged(previousBeneficiary, newBeneficiary);
    }

    /// @inheritdoc IFranchiser
    function delegate(address to) external onlyBeneficiary {
        votingToken.delegate(to);
    }

    /// @inheritdoc IFranchiser
    function recall(address to) external onlyOwner {
        ERC20(address(votingToken)).safeTransfer(
            to,
            votingToken.balanceOf(address(this))
        );
    }
}
