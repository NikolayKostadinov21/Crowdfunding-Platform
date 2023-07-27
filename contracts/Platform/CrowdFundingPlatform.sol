// SPDX-License-Identifier: GPL-3.0

import { CustomErrors } from "../Utils/CustomErrors.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "../Proxy/UUPSProxiable.sol";

pragma solidity ^0.8.20;

/**
 * @title Crowdfunding Platform contract
 */
contract CrowdFundingPlatform is UUPSProxiable {

    /// @notice Allowing for IERC20 type from the SafeERC20 library to be accessed in the contract.
    using SafeERC20 for IERC20;

    /// @notice The maximal duration of the crowdfunding platform
    uint256 public maxDuration;
    /// @notice Counter that increments on every new project. Acts as ID for project
    uint256 public counter;
    /// @notice FundMe token
    IERC20 FundMeToken;

    struct CrowdFundingProject {
        /// @notice The total amount of invested funds in a project
        uint256 investedFunds;
        /// @notice The funding goal of a project
        uint256 fundingGoal;
        /// @notice The maximal timeline of a project
        uint256 timeline;
        /// @notice Owner of a project
        address owner;
        /// @notice Flag marking whether a project exists
        bool exists;
        /// @notice Flag marking whether a project is successful
        bool successful;
    }

    // ================================================================
    // |                           EVENTS                             |
    // ================================================================

    /// @notice Emitted when a new crowdfunding project is created
    event InitializeCrowdfundingProject(CrowdFundingProject crowdFundingProject);

    /// @notice Emitted when funds are invested in a crowdfunding project
    event FundsInvested(IERC20 _token, CrowdFundingProject crowdFundingProject, uint256 amount, address indexed investor);

    /// @notice Emitted when the owner of a crowdfunding project withdraws its funds
    event FundsWithdrawn(IERC20 _token, CrowdFundingProject crowdFundingProject, uint256 amount, address indexed owner);

    /// @notice Emitted when an investor of a crowdfunding project refunds their funds
    event FundsRefunded(IERC20 _token, CrowdFundingProject crowdFundingProject, uint256 amount, address indexed investor);

    /// @notice Emitted when an investor of a crowdfunding project revokes staked funds
    event FundsRevoked(IERC20 _token, CrowdFundingProject crowdFundingProject, uint256 amount, address indexed investor);

    /// @notice Emitted when the owner of a crowdfunding project terminates it
    event TerminateCrowdfundingProject(CrowdFundingProject crowdFundingProject, address indexed owner);

    /**
     * @notice customerInvestedFunds Stores each investor's staked funds in the respective project
     * @dev projectId -> investor's address -> invested funds
     */
    mapping(uint256 => mapping(address => uint256)) public customerInvestedFunds;
    /// @notice crowdFundingProjects Stores all crowdfunding projects by their corresponding id
    mapping(uint256 => CrowdFundingProject) public crowdFundingProjects;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    /**
     * @dev initialize function that has the role of implementation contract constructor
     * @dev Setting the owner to be the sender and declaring the maximal duration of the platform
     * @param _maxDuration duration of the platform
     */
    function initialize(uint256 _maxDuration, IERC20 _fundMeToken) initializer public {
        require(_maxDuration > block.timestamp, "The duration cannot be before the current time");
        __Ownable_init(); /// @dev In newer versions, the __Ownable_init function expects parameter
        maxDuration = _maxDuration;
        FundMeToken = _fundMeToken;
    }

    /// @dev Checks if the project exists in the platform
    modifier projectExists(uint256 projectId) {
        if (!crowdFundingProjects[projectId].exists) revert CustomErrors.PROJECT_DOESNT_EXIST();
        _;
    }

    /// @dev Checks if the timeline isn't reached
    modifier isBeforeTimeline(uint256 timeline) {
        if (block.timestamp > timeline) revert CustomErrors.THE_TIMELINE_HAS_EXCEEDED();
        _;
    }

    /// @dev Checks if the successful flag for a project is false
    modifier onlyIfNotSuccessful(uint256 projectId) {
        if (crowdFundingProjects[projectId].successful) revert CustomErrors.PROJECT_IS_SUCCESSFUL();
        _;
    }

    /// @dev Checks if the invoker is the owner of the project
    modifier onlyOwnerOfProject(uint256 projectId) {
        if (!(msg.sender == crowdFundingProjects[projectId].owner)) revert CustomErrors.NOT_THE_OWNER_OF_THE_PROJECT();
        _;
    }

    /// @dev Checks if you have investments in a project and if you have already been refunded for your investments
    modifier onlyNonRefundedInvestors(uint256 projectId) {
        if (!(customerInvestedFunds[projectId][msg.sender] > 0)) revert CustomErrors.ONLY_NON_REFUNDED_INVESTORS_ALLOWED();
        _;
    }

    /**
     * @notice Initializing new crowdfunding project
     * @dev Steps:
     *      Increasing the value of counter by one
     *      Assigning the appropriate values for the newly created project
     *      Emit an event
     * @param _fundingGoal the funds that are required for a project to be successful
     * @param _timeline the maximal timeline of the project
     */
    function initializeCrowdfundingProject(uint256 _fundingGoal, uint256 _timeline)
        external
    {
        if (_timeline > maxDuration) revert CustomErrors.THE_DEADLINE_HAS_EXCEEDED();
        counter += 1;

        crowdFundingProjects[counter] = CrowdFundingProject({
            investedFunds: 0,
            fundingGoal: _fundingGoal,
            timeline: block.timestamp + _timeline,
            owner: msg.sender,
            exists: true,
            successful: false
        });
        emit InitializeCrowdfundingProject(crowdFundingProjects[counter]);
    }

    /**
     * @notice Terminating an ongoing crowdfunding project
     * @dev Steps:
     *      Exceed the timeline of the project
     *      Make the project unsuccessful
     *      Emit an event
     * @param projectId the id of the project
     */
    function terminateCrowdfundingProject(uint256 projectId)
        projectExists(projectId)
        isBeforeTimeline(crowdFundingProjects[projectId].timeline)
        onlyOwnerOfProject(projectId)
        onlyIfNotSuccessful(projectId)
        external
    {
        CrowdFundingProject storage crowdFundingProject = crowdFundingProjects[projectId];
        crowdFundingProject.timeline = 0;
        crowdFundingProject.successful = false;
        emit TerminateCrowdfundingProject(crowdFundingProject, msg.sender);
    }

    /**
     * @notice Investing funds in a crowdfunding project
     * @dev Steps:
     *      Check if the project exists and if it's before the timeline
     *      Check is @param amount > 0
     *      Transfer the funds to the project
	 *      Update the invested funds in the crowdFundingProjects and customerInvestedFunds mappings
     *      If after the transfer, the invested funds are greater or equal the funding goal, then make the project successful
     *      Emit an event
     * @param projectId the id of the crowdfunding project
     * @param amount amount of funds to be invested
     */
    function investFunds(uint256 projectId, uint256 amount)
        projectExists(projectId)
        isBeforeTimeline(crowdFundingProjects[projectId].timeline)
        external
    {
        CrowdFundingProject storage crowdFundingProject = crowdFundingProjects[projectId];
        if (amount == 0) revert CustomErrors.AMOUNT_CANNOT_BE_ZERO();
        if (crowdFundingProject.successful) revert CustomErrors.PROJECT_ALREADY_ACHIEVED_ITS_GOAL();

        FundMeToken.safeTransferFrom(msg.sender, address(this), amount);

        crowdFundingProject.investedFunds += amount;
        customerInvestedFunds[projectId][msg.sender] += amount;
        if (crowdFundingProject.fundingGoal <= crowdFundingProject.investedFunds) {
            crowdFundingProject.successful = true;
        }

        emit FundsInvested(FundMeToken, crowdFundingProject, amount, msg.sender);
    }

    /**
     * @notice Revoking Funds function
     * @dev Steps:
     *      Check if the product exists and if it's before its timeline
     *      Check if investor has any investments in the particular project
     *      Check if the project already achieved its goal
     *      Transfer the requested amount to the investor
     *      Decrease the invested funds in the project
     *      Decrease the amount of funds in the mapping customerInvestedFunds for the investor
     *      Emit an event
     * @param projectId the id of the crowdfunding project
     * @param amount amount of funds to be revoked
     */
    function revokeFunds(uint256 projectId, uint256 amount)
        external
        projectExists(projectId)
        isBeforeTimeline(crowdFundingProjects[projectId].timeline)
        onlyNonRefundedInvestors(projectId)
    {
        uint256 _investedFunds = customerInvestedFunds[projectId][msg.sender];
        CrowdFundingProject storage crowdFundingProject = crowdFundingProjects[projectId];
        if (amount == 0) revert CustomErrors.AMOUNT_CANNOT_BE_ZERO();
        if (crowdFundingProject.successful) revert CustomErrors.PROJECT_ALREADY_ACHIEVED_ITS_GOAL();
        if (_investedFunds < amount) revert CustomErrors.NOT_ENOUGH_TOKENS();

        FundMeToken.transfer(msg.sender, amount);

        crowdFundingProject.investedFunds -= amount;
        customerInvestedFunds[projectId][msg.sender] -= amount;

        emit FundsRevoked(FundMeToken, crowdFundingProject, _investedFunds, msg.sender);
    }

    /**
     * @notice Withdrawing Funds function
     * @dev Steps:
     *      Check if the project is existing, is finished and is successful
     *      Check if it's the owner that invokes the function
     *      transfer tokens to owner of the project
     *      Delete the project
     *      Emit an event
     * @param projectId the id of the crowdfunding project
     */
    function withdrawFunds(uint256 projectId)
        projectExists(projectId)
        onlyOwnerOfProject(projectId)
        external
    {
        CrowdFundingProject storage crowdFundingProject = crowdFundingProjects[projectId];
        if (!crowdFundingProject.successful) revert CustomErrors.PROJECT_ISNT_SUCCESSFUL();

        FundMeToken.safeTransfer(msg.sender, crowdFundingProject.investedFunds);

        delete crowdFundingProjects[projectId];
        emit FundsWithdrawn(FundMeToken, crowdFundingProject, crowdFundingProject.investedFunds, msg.sender);
    }

    /**
     * @notice Refund Funds function
     * @dev Steps:
    *       Checks if the project exists and if it's unsuccessful
     *      Check if beneficiary has invested something in the particular project
     *      If the investor has already refunded all of their tokens, prevent them from invoking this function for this project
     *      Transfer tokens to beneficiary
     *      Emit an event
     *      Delete the investor's staked funds in the project
     *      If everyone has refunded successfully their tokens, delete the project
     * @param projectId the id of the crowdfunding project
     */
    function refundFunds(uint256 projectId)
        projectExists(projectId)
        onlyIfNotSuccessful(projectId)
        onlyNonRefundedInvestors(projectId)
        external
    {
        uint256 _investedFunds = customerInvestedFunds[projectId][msg.sender];
        CrowdFundingProject storage crowdFundingProject = crowdFundingProjects[projectId];

        if (block.timestamp <= crowdFundingProject.timeline) revert CustomErrors.TIMELINE_HASNT_EXCEEDED();

        FundMeToken.safeTransfer(msg.sender, _investedFunds);
        crowdFundingProject.investedFunds -= _investedFunds;

        emit FundsRefunded(FundMeToken, crowdFundingProject, _investedFunds, msg.sender);

        if (crowdFundingProject.investedFunds == 0) {
            delete crowdFundingProjects[projectId];
        }
        delete customerInvestedFunds[projectId][msg.sender];
    }

    /**
     * @notice Updates the address of the logic contract
     * @dev Can be invoked only by the owner of the platform contract
     * @param newAddress the address of the new logic contract
     */
    function updateCode(address newAddress)
        onlyOwner
        override
        external
    {
        _updateCodeAddress(newAddress);
    }
}