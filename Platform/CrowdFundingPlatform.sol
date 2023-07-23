// SPDX-License-Identifier: GPL-3.0

import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC20/IERC20.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC20/utils/SafeERC20.sol";
import "../Proxy/UUPSProxiable.sol";

pragma solidity ^0.8.20;

/**
 * @title Crowdfunding Platform contract
 */
contract CrowdFundingPlatform is UUPSProxiable {

    /// @notice Allowing for IERC20 type from the SafeERC20 library to be accessed in the contract.
    using SafeERC20 for IERC20;

    /// @notice The maximal duration of the crowdfunding platform
    uint256 maxDuration;
    /// @notice Counter that increments on every new project. Acts as ID for project
    uint256 public counter;

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
    mapping(uint256 => CrowdFundingProject) crowdFundingProjects;

    /// @dev _disableInitializers is used to prevent initialization of the implementation contract
    constructor() {
        _disableInitializers();
    }

    // @audit missed comment
    function initialize(uint256 _maxDuration) initializer public {
        require(_maxDuration > block.timestamp, "The duration cannot be before the current time");
        __Ownable_init(msg.sender);
        maxDuration = _maxDuration;
    }

    /// @dev Checks if the project exists in the platform
    modifier projectExists(uint256 projectId) {
        require(crowdFundingProjects[projectId].exists, "The project doesn't exists!");
        _;
    }

    /// @dev Checks if the timeline has exceeded
    modifier isPastTimeline(uint256 timeline) {
        require(block.timestamp > timeline, "The timeline hasn't exceeded!");
        _;
    }

    /// @dev Checks if the deadline has exceeded
    modifier isBeforeDeadline(uint256 timeline) {
        require(timeline <= maxDuration, "The deadline has exceeded!");
        _;
    }

    /// @dev Checks if the timeline isn't reached
    modifier isBeforeTimeline(uint256 timeline) {
        require(block.timestamp <= timeline, "The timeline has exceeded!");
        _;
    }

    /// @dev Checks if the successful flag for a project is true
    modifier onlyIfSuccessful(uint256 projectId) {
        require(crowdFundingProjects[projectId].successful, "Project isn't successful, you can't withdraw!");
        _;
    }

    /// @dev Checks if the successful flag for a project is false
    modifier onlyIfNotSuccessful(uint256 projectId) {
        require(!crowdFundingProjects[projectId].successful, "Project is successful, you can't refund!");
        _;
    }

    /// @dev Checks if the invoker is the owner of the project
    modifier onlyOwnerOfProject(uint256 projectId) {
        require(msg.sender == crowdFundingProjects[projectId].owner, "Unauthorized!");
        _;
    }

    /// @dev Checks if you have investments in a project and if you have already been refunded for your investments
    modifier onlyNonRefundedInvestors(uint256 projectId) {
        require(customerInvestedFunds[projectId][msg.sender] > 0, "Only non refunded investors allowed!");
        _;
    }

    /**
     * @notice Initializing new crowdfunding project
     * @dev
     * @dev
     *
     *
     * @param _fundingGoal
     * @param _timeline
     */
    function initializeCrowdfundingProject(uint256 _fundingGoal, uint256 _timeline)
        isBeforeDeadline(_timeline)
        external
    {
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
     * @notice Initializing new crowdfunding project
     * @dev
     * @dev
     *
     * Steps:
     * 1. Exceed the timeline of the project
     * 2. Make the project unsuccessful
     *
     * @param projectId
     */
    function terminateCrowdfundingProject(uint256 projectId)
        projectExists(projectId)
        isBeforeTimeline(crowdFundingProjects[projectId].timeline)
        onlyOwnerOfProject(projectId)
        onlyIfNotSuccessful(projectId)
        external
    {
        crowdFundingProjects[projectId].timeline = 0;
        crowdFundingProjects[projectId].successful = false;
        emit TerminateCrowdfundingProject(crowdFundingProjects[projectId], msg.sender);
    }

    /**
     * @notice Investing Funds function
     * @dev
     *
     * Steps:
     * 1. Check if the project exists and if it's still going, i.e. not successful, fundingGoal not achieved
     * 2. Amount > 0
     * 3. transfer the funds to the project
	 * 4. update the invested funds in the crowdFundingProjects and customerInvestedFunds mappings
     * 5. If after the transfer, the invested funds are greater or equal the funding goal, then make the project successful
     * 6. Emit an event
     *
     * @param _token
     * @param projectId
     * @param amount
     */
    function investFunds(IERC20 _token, uint256 projectId, uint256 amount)
        projectExists(projectId)
        isBeforeTimeline(crowdFundingProjects[projectId].timeline)
        external
    {
        require(amount > 0, "Amount cannot be equal to zero!");
        require(!crowdFundingProjects[projectId].successful, "The project has already achieved its goal!");

        _token.safeTransferFrom(msg.sender, address(this), amount);

        crowdFundingProjects[projectId].investedFunds += amount;
        customerInvestedFunds[projectId][msg.sender] += amount;
        if (crowdFundingProjects[projectId].fundingGoal <= crowdFundingProjects[projectId].investedFunds) {
            crowdFundingProjects[projectId].successful = true;
        }

        emit FundsInvested(_token, crowdFundingProjects[projectId], amount, msg.sender);
    }

    /**
     * @notice Revoking Funds function
     * @dev
     *
     * Steps:
     * 1. Exceed the timeline of the project
     * 2. Make the project unsuccessful
     *
     * @param _token
     * @param projectId
     * @param amount
     */
    function revokeFunds(IERC20 _token, uint256 projectId, uint256 amount)
        external
        projectExists(projectId)
        isBeforeTimeline(crowdFundingProjects[projectId].timeline)
        onlyNonRefundedInvestors(projectId)
    {
        require(amount > 0, "Amount cannot be equal to zero!");
        require(!crowdFundingProjects[projectId].successful, "The project has already achieved its goal!");
        require(customerInvestedFunds[projectId][msg.sender] >= amount, "You don't have that amount of tokens!");

        _token.transfer(msg.sender, amount);

        crowdFundingProjects[projectId].investedFunds -= amount;
        customerInvestedFunds[projectId][msg.sender] -= amount;

        emit FundsRevoked(_token, crowdFundingProjects[projectId], customerInvestedFunds[projectId][msg.sender], msg.sender);
    }

    /**
     * @notice Withdrawing Funds function
     * @dev
     *
     * Steps:
     * 1. Check if it's the owner that invokes the function
     * 2. Check if the project is existing, is finished and is successful, if yes go to 3.
     * 3. transfer tokens to owner of the project
     * 4. Delete the project
     * 5. Emit an event
     *
     * @param _token
     * @param projectId
     * @param amount
     */
    function withdrawFunds(IERC20 _token, uint256 projectId)
        projectExists(projectId)
        onlyOwnerOfProject(projectId)
        onlyIfSuccessful(projectId)
        external
    {
        _token.safeTransfer(msg.sender, crowdFundingProjects[projectId].investedFunds);
        delete crowdFundingProjects[projectId];
        emit FundsWithdrawn(_token, crowdFundingProjects[projectId], crowdFundingProjects[projectId].investedFunds, msg.sender);
    }

    /**
     * @notice Refund Funds function
     * @dev
     *
     * Steps:
     * 1. Check if beneficiary has invested something in the particular campaign
     *    1.1 if yes, has he already refunded all of his tokens -> if that's true prevent him from repeating this function
     *    1.2 if no, go to 2.
     * 2. Transfer tokens to beneficiary
     * 3. If everyone has refunded successfully their tokens -> Delete the campaign
     * 4. Emit an event
     *
     * @param _token
     * @param projectId
     * @param amount
     */
    function refundFunds(IERC20 _token, uint256 projectId)
        projectExists(projectId)
        isPastTimeline(crowdFundingProjects[projectId].timeline)
        onlyIfNotSuccessful(projectId)
        onlyNonRefundedInvestors(projectId)
        external
    {
        _token.safeTransfer(msg.sender, customerInvestedFunds[projectId][msg.sender]);
        crowdFundingProjects[projectId].investedFunds -= customerInvestedFunds[projectId][msg.sender];
        if (crowdFundingProjects[projectId].investedFunds == 0) {
            delete crowdFundingProjects[projectId];
        }
        delete customerInvestedFunds[projectId][msg.sender];
        emit FundsRefunded(_token, crowdFundingProjects[projectId], customerInvestedFunds[projectId][msg.sender], msg.sender);
    }

    function updateCode(address newAddress) onlyOwner override external {
        _updateCodeAddress(newAddress);
    }
}