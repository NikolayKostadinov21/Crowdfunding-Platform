// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.20;

import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC20/IERC20.sol";

contract FundMeFaucet {
    IERC20 public FundMeToken;

    uint256 public constant lockTime = 1 minutes;
    uint256 public constant withdrawalAmount = 50 * (10**18);

    mapping(address => uint256) nextAccessTime;

    event Deposit(address indexed from, uint256 indexed amount);
    event TransferRequestedTokens(address indexed from, uint256 indexed amount);

    constructor(address _token) {
        FundMeToken = IERC20(_token);
    }

    receive() external payable {
        emit Deposit(msg.sender, msg.value);
    }

    function getBalance() external view returns (uint256) {
        return FundMeToken.balanceOf(address(this));
    }

    function requestTokens() external {
        require(msg.sender != address(0), "Request must not originate from a zero account");
        require(block.timestamp >= nextAccessTime[msg.sender],"Insufficient time elapsed since last withdrawal - try again later.");
        require(FundMeToken.balanceOf(address(this)) >= withdrawalAmount, "Insufficient balance in faucet for withdrawal request");

        nextAccessTime[msg.sender] = block.timestamp + lockTime;
        FundMeToken.transfer(msg.sender, withdrawalAmount);
        emit TransferRequestedTokens(msg.sender, withdrawalAmount);
    }
}