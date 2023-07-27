// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.20;

library CustomErrors {
    // ================================================================
    // |                           ERRORS                             |
    // ================================================================


    /*                              PLATFORM ERRORS                                   */

    /// @notice Error thrown if the project doesn't exists
    error PROJECT_DOESNT_EXIST();

    /// @notice Error thrown if the timeline hasn't exceeded
    error TIMELINE_HASNT_EXCEEDED();

    /// @notice Error thrown if the deadline has exceeded
    error THE_DEADLINE_HAS_EXCEEDED();

    /// @notice Error thrown if the timeline has exceeded
    error THE_TIMELINE_HAS_EXCEEDED();

    /// @notice Error thrown if project isn't successful, i.e. you can't withdraw
    error PROJECT_ISNT_SUCCESSFUL();

    /// @notice Error thrown if project is successful, i.e. you can't refund
    error PROJECT_IS_SUCCESSFUL();

    /// @notice Error thrown if non-owner of a project invokes particular function
    error NOT_THE_OWNER_OF_THE_PROJECT();

    /// @notice Error thrown when only non refunded investors are allowed
    error ONLY_NON_REFUNDED_INVESTORS_ALLOWED();

    /// @notice Error thrown if the amount is equal to zero
    error AMOUNT_CANNOT_BE_ZERO();

    /// @notice Error thrown if the project has already achieved its goal
    error PROJECT_ALREADY_ACHIEVED_ITS_GOAL();


    /*                              FAUCET ERRORS                                    */

    /// @notice Error thrown when you don't have that amount of tokens
    error NOT_ENOUGH_TOKENS();

    /// @notice Error thrown request originate from a zero account!
    error REQUEST_CANNOT_ORIGINATE_FROM_ZERO_ACCOUNT();

    /// @notice Error thrown if insufficient time elapsed since last withdrawal
    error INSUFFICIENT_TIME_ELAPSED_SINCE_LAST_WITHDRAWAL();

    /// @notice Error thrown if there is insufficient balance in faucet for withdrawal request
    error INSUFFICIENT_BALANCE_IN_FAUCET_FOR_WITHDRAWAL_REQUEST();

    /// @notice Error thrown if you don't have enough exchanged funds for FundMe token
    error INSUFFICIENT_EXCHANGED_FUNDS_FOR_FUNDME_TOKEN();

    /// @notice
    error EXCHANGING_VALUE_CANNOT_BE_EQUAL_TO_ZERO();


    /*                               PROXIABLE ERRORS                               */

    /// @notice Error thrown if trying to upgrade the zeroth address
    error UUPSPROXIABLE_NOT_UPGRADABLE();

    /// @notice Error thrown if trying to upgrade the incorrect slot
    error UUPSPROXIABLE_NOT_COMPATIBLE_LOGIC();

    /// @notice Error thrown if trying to upgrade the same logic contract
    error UUPSPROXIABLE_PROXY_LOOP();


    /*                               PROXY ERRORS                                  */

    /// @notice Error thrown if trying to point to the zeroth address
    error UUPSPROXY_ZERO_ADDRESS();

    /// @notice Error thrown if trying to initialize already initialized implementation contract
    error UUPSPROXY_ALREADY_INITIALIZED();
}