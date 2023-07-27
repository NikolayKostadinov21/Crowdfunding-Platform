// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.20;

import { UUPSUtils } from "./UUPSUtils.sol";
import { CustomErrors } from "../Utils/CustomErrors.sol";
import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import "@openzeppelin/contracts/proxy/Proxy.sol";

/**
 * @title UUPS (Universal Upgradeable Proxy Standard) Proxy
 *
 * NOTE:
 * - Compliant with [Universal Upgradeable Proxy Standard](https://eips.ethereum.org/EIPS/eip-1822)
 * - Compliant with [Standard Proxy Storage Slots](https://eips.ethereum.org/EIPS/eip-1967)
 * - It defines a fallback function that delegates all calls to the implementation
 */
contract UUPSProxy is Proxy {
    /**
     * @dev Proxy initialization function.
     *      This should only be called once and it is permission-less.
     * @param initialAddress Initial logic contract code address to be used.
     */
    function initializeProxy(address initialAddress) external {
        if (initialAddress == address(0)) revert CustomErrors.UUPSPROXY_ZERO_ADDRESS();
        if (UUPSUtils.implementation() != address(0)) revert CustomErrors.UUPSPROXY_ALREADY_INITIALIZED();
        UUPSUtils.setImplementation(initialAddress);
    }

    /// @dev Proxy._implementation implementation
    function _implementation() internal virtual override view returns (address)
    {
        return UUPSUtils.implementation();
    }
}