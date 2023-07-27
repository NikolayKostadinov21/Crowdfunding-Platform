// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.20;

import { CustomErrors } from "../Utils/CustomErrors.sol";
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
    uint256 public constant withdrawalAmount = 0.01 * (10**18);

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
        if (msg.value == 0) revert CustomErrors.EXCHANGING_VALUE_CANNOT_BE_EQUAL_TO_ZERO();

        exchangedFunds[msg.sender] += msg.value;
    }

    /**
     * @notice Function to request FundMe tokens
     * @dev If you have sufficient FundMe tokens and 1 minute has passed since the last transfer,
     *      you are eligible to get funds from the function
     */
    function requestTokens() external {
        if (msg.sender == address(0)) revert CustomErrors.REQUEST_CANNOT_ORIGINATE_FROM_ZERO_ACCOUNT();
        if (block.timestamp < nextAccessTime[msg.sender]) revert CustomErrors.INSUFFICIENT_TIME_ELAPSED_SINCE_LAST_WITHDRAWAL();
        if (FundMeToken.balanceOf(address(this)) < withdrawalAmount) revert CustomErrors.INSUFFICIENT_BALANCE_IN_FAUCET_FOR_WITHDRAWAL_REQUEST();
        if (exchangedFunds[msg.sender] < withdrawalAmount) revert CustomErrors.INSUFFICIENT_EXCHANGED_FUNDS_FOR_FUNDME_TOKEN();

        nextAccessTime[msg.sender] = block.timestamp + lockTime;
        FundMeToken.transfer(msg.sender, withdrawalAmount * 100000); /// @dev regulate this number, right now it's * 1000000, because of testing purposes
        exchangedFunds[msg.sender] -= withdrawalAmount;

        emit TransferRequestedTokens(msg.sender, withdrawalAmount);
    }
}