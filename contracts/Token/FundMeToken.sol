// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

/**
 * @title FundMe contract that represents the FundMe token
 */
contract FundMeToken is ERC20 {
    /**
     * @dev Constructor that gives sender all of existing tokens.
     */
    constructor(uint256 initialSupply) ERC20("FundMe Token", "FMT") {
        _mint(msg.sender, initialSupply);
    }
}