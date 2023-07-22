// SPDX-License-Identifier: GPL-3.0

import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC20/IERC20.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC20/utils/SafeERC20.sol";
import "../Proxy/UUPSProxiable.sol";

pragma solidity ^0.8.20;

contract CrowdFundingPlatform is UUPSProxiable {

    /// Allowing for IERC20 type from the SafeERC20 library to be accessed in the contract.
    using SafeERC20 for IERC20;

    uint256 maxDuration;
    uint256 public counter;
    address owner;

    struct CrowdFundingProject {
        uint256 investedFunds;
        uint256 fundingGoal;
        uint256 timeline;
        address owner;
        bool exists;
        bool successful;
    }

    event InitializeCrowdfundingProject(CrowdFundingProject crowdFundingProject);
    event FundsInvested(IERC20 _token, CrowdFundingProject crowdFundingProject, uint256 amount, address indexed investor);
    event FundsWithdrawn(IERC20 _token, CrowdFundingProject crowdFundingProject, uint256 amount, address indexed owner);
    event FundsRefunded(IERC20 _token, CrowdFundingProject crowdFundingProject, uint256 amount, address indexed investor);
    event FundsRevoked(IERC20 _token, CrowdFundingProject crowdFundingProject, uint256 amount, address indexed investor);
    event TerminateCrowdfundingProject(CrowdFundingProject crowdFundingProject, address indexed owner);

    mapping(uint256 => CrowdFundingProject) crowdFundingProjects;
    mapping(uint256 => mapping(address => uint256)) public customerInvestedFunds;

    function initialize(uint256 _maxDuration) initializer public {
        require(_maxDuration > block.timestamp, "The duration cannot be before the current time");
        maxDuration = _maxDuration;
        owner = msg.sender;
    }

    modifier projectExists(uint256 projectId) {
        require(crowdFundingProjects[projectId].exists, "The project doesn't exists!");
        _;
    }

    modifier isPastTimeline(uint256 timeline) {
        require(block.timestamp > timeline, "The timeline hasn't exceeded!");
        _;
    }

    modifier isBeforeDeadline(uint256 timeline) {
        require(timeline <= maxDuration, "The deadline has exceeded!");
        _;
    }

    modifier isBeforeTimeline(uint256 timeline) {
        require(block.timestamp <= timeline, "The timeline has exceeded!");
        _;
    }

    modifier onlyIfSuccessful(uint256 projectId) {
        require(crowdFundingProjects[projectId].successful, "Project isn't successful, you can't withdraw!");
        _;
    }

    modifier onlyIfNotSuccessful(uint256 projectId) {
        require(!crowdFundingProjects[projectId].successful, "Project is successful, you can't refund!");
        _;
    }

    modifier onlyOwnerOfProject(uint256 projectId) {
        require(msg.sender == crowdFundingProjects[projectId].owner, "Unauthorized!");
        _;
    }

    modifier onlyNonRefundedInvestors(uint256 projectId) {
        require(customerInvestedFunds[projectId][msg.sender] > 0, "Only non refunded investors allowed!");
        _;
    }

    modifier onlyOwner {
        require(msg.sender == owner, "Unauthorized!");
        _;
    }

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

    function updateCode(address newAddress) onlyOwner external {
        _updateCodeAddress(newAddress);
    }
}