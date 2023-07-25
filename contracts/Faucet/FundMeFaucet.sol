// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * @title FundMeFaucet contract
 * @notice FundMeFaucet contract represents the faucet where you can request FundMe tokens
 */
contract FundMeFaucet {
    /// @notice FundMe token interface
    IERC20 public FundMeToken;

    /// @notice Time locker that restricts token requests within a 1-minute interval
    uint256 public constant lockTime = 1 minutes;
    /// @notice The amount of tokens available for withdrawal
    uint256 public constant withdrawalAmount = 0.1 * (10**18);

    /// @notice Mapping that stores the last withdrawal time for an address
    mapping(address => uint256) public nextAccessTime;
    /// @notice Mapping that stores the exchanged funds per address
    mapping(address => uint256) public exchangedFunds;

    // ================================================================
    // |                           EVENTS                             |
    // ================================================================

    /// @notice Emitted when an amount of funds is deposited to the Faucet from an address
    event Deposit(address indexed from, uint256 indexed amount);

    /// @notice Emitted when an amount of requested tokens is transferred to the respective claimant
    event TransferRequestedTokens(address indexed from, uint256 indexed amount);

    constructor(address _token) {
        FundMeToken = IERC20(_token);
    }

    /// @dev Emits a Deposit event when funds are successfully deposited to the contract
    receive() external payable {
        emit Deposit(msg.sender, msg.value);
    }

    /// @return uint256 Returns the amount of FundMe tokens that the Faucet contract possesses
    function getBalance() external view returns (uint256) {
        return FundMeToken.balanceOf(address(this));
    }

    /**
     * @notice Function to exchange ETH for FundMe tokens
     * @dev Adds the exchanged funds to the exchangedFunds mapping for the respective address
     */
    function depositFunds() external payable {
        require(msg.value != 0, "Exchanging value cannot be equal to zero!");
        exchangedFunds[msg.sender] += msg.value;
    }

    /**
     * @notice Function to request FundMe tokens
     * @dev If you have sufficient FundMe tokens and 1 minute has passed since the last transfer,
     *      you are eligible to get funds from the function
     */
    function requestTokens() external {
        require(msg.sender != address(0), "Request cannot originate from a zero account!");
        require(block.timestamp >= nextAccessTime[msg.sender],"Insufficient time elapsed since last withdrawal!");
        require(FundMeToken.balanceOf(address(this)) >= withdrawalAmount, "Insufficient balance in faucet for withdrawal request!");
        require(exchangedFunds[msg.sender] >= withdrawalAmount, "You don't have enough exchanged funds for FundMe token!");

        nextAccessTime[msg.sender] = block.timestamp + lockTime;
        FundMeToken.transfer(msg.sender, withdrawalAmount);
        exchangedFunds[msg.sender] -= withdrawalAmount;

        emit TransferRequestedTokens(msg.sender, withdrawalAmount);
    }
}