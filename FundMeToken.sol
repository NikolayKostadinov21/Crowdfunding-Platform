// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.20;

import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC20/ERC20.sol";

contract FundMe is ERC20 {
    /**
     * @dev Constructor that gives sender all of existing tokens.
     */
    constructor(uint256 initialSupply) ERC20("FundMe Token", "FMT") {
        _mint(msg.sender, initialSupply);
    }
}