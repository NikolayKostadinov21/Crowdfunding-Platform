// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.20;
/**
 * @title UUPS (Universal Upgradeable Proxy Standard) Utils Shared Library
 */
library UUPSUtils {
    /**
     * @dev Implementation slot constant
     * Using https://eips.ethereum.org/EIPS/eip-1967 standard
     * Storage slot 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc
     * (obtained as bytes32(uint256(keccak256('eip1967.proxy.implementation')) - 1)).
     */
    bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

    /// @dev Get implementation address
    function implementation()
        internal
        view
        returns
        (address impl)
    {
        assembly {
            impl := sload(_IMPLEMENTATION_SLOT)
        }
    }

    /// @dev Set new implementation address
    function setImplementation(address codeAddress) internal
    {
        assembly {
            sstore(
                _IMPLEMENTATION_SLOT,
                codeAddress
            )
        }
    }
}