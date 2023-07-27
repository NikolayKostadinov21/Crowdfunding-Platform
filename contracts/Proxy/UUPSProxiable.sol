// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.20;

import { UUPSUpgradeable } from "@openzeppelin/contracts/proxy/utils/UUPSUpgradeable.sol";
import { UUPSUtils } from "./UUPSUtils.sol";
import { CustomErrors } from "../Utils/CustomErrors.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

/**
 * @title UUPSProxiable (Universal Upgradeable Proxy Standard) Proxiable abstract contract
 */
abstract contract UUPSProxiable is OwnableUpgradeable {

    /// @notice Emitted when a new implementation address is set
    event CodeUpdated(bytes32 uuid, address codeAddress);

    /**
     * @notice To be overwritten by implementation contract
     * @dev In the overwritten body invoke the _updateCodeAddress function
     * @param newAddress the new implementation contract address
     */
    function updateCode(address newAddress) external virtual;

    /// @return codeAddress Get current implementation code address
    function getCodeAddress()
        public
        view
        returns
        (address codeAddress)
    {
        return UUPSUtils.implementation();
    }

    /**
     * @dev Proxiable UUID marker function, this would help to avoid wrong logic
     *      contract to be used for upgrading.
     * @return bytes32 Returns the implementation slot
     * NOTE: The semantics of the UUID deviates from the actual UUPS standard,
     *       where it is equivalent of _IMPLEMENTATION_SLOT.
     */
    function proxiableUUID()
        public
        pure
        returns
        (bytes32)
    {
        return 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;
    }

    /**
     * @dev Updating the code address.
     *      It is internal, so the derived contract could setup its own permission logic.
     */
    function _updateCodeAddress(address newAddress) internal
    {
        if (UUPSUtils.implementation() == address(0)) revert CustomErrors.UUPSPROXIABLE_NOT_UPGRADABLE();
        if (proxiableUUID() != UUPSProxiable(newAddress).proxiableUUID()) revert CustomErrors.UUPSPROXIABLE_NOT_COMPATIBLE_LOGIC();
        if (address(this) == newAddress) revert CustomErrors.UUPSPROXIABLE_PROXY_LOOP();

        UUPSUtils.setImplementation(newAddress);
        emit CodeUpdated(proxiableUUID(), newAddress);
    }
}