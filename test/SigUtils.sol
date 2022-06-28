// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.15;

/// @notice lightly modified from https://github.com/kulkarohan/deposit/blob/7904c779e5074f68fc709f5f080e923a36155f01/test/utils/SigUtils.sol
library SigUtils {
    bytes32 private constant PERMIT_TYPEHASH =
        0x6e71edae12b1b97f4d1f60370fef10105fa2faae0126114a169c64845d6126c9;

    function getTypedDataHash(
        bytes32 DOMAIN_SEPARATOR,
        address owner,
        address spender,
        uint256 value,
        uint256 nonce,
        uint256 deadline
    ) internal pure returns (bytes32) {
        bytes32 structHash = keccak256(
            abi.encode(PERMIT_TYPEHASH, owner, spender, value, nonce, deadline)
        );
        return
            keccak256(
                abi.encodePacked("\x19\x01", DOMAIN_SEPARATOR, structHash)
            );
    }
}
