// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.20;

import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import {ERC1967Utils} from "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/proxy/ERC1967/ERC1967Utils.sol";
/**
 * @title UUPS (Universal Upgradeable Proxy Standard) Proxy
 *
 * NOTE:
 * - Compliant with [Universal Upgradeable Proxy Standard](https://eips.ethereum.org/EIPS/eip-1822)
 * - Compiiant with [Standard Proxy Storage Slots](https://eips.ethereum.org/EIPS/eip-1967)
 * - Implements delegation of calls to the crowdfunding platform contract, with proper forwarding of
 *   return values and bubbling of failures.
 * - It defines a fallback function that delegates all calls to the implementation.
 */
abstract contract UUPSProxy is ERC1967Proxy {

        /**
     * @dev Proxy initialization function.
     *      This should only be called once and it is permission-less.
     * @param initialAddress Initial logic contract code address to be used.
     */
    function initializeProxy(address initialAddress, bytes memory data) external {
        require(initialAddress != address(0), "UUPSProxy: zero address");
        require(_implementation() == address(0), "UUPSProxy: already initialized");

        // Create your own library
        ERC1967Utils.upgradeToAndCall(initialAddress, data);
    }

    /// @dev Proxy._implementation implementation
    function _implementation() internal virtual override view returns (address)
    {
        return _implementation();
    }

}