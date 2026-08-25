// contracts/
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";


contract Insurance is ReentrancyGuard {
    address public insurer;

    uint public policyCounter;

    struct Policy {
        address policyHolder;
        uint premium;
        uint coverageAmount;
        bool isClaimed;
        bool isClaimApproved;
        bool premiumPaid;
        bool payoutDone;
    }

    mapping(uint => Policy) public policies;


    constructor() {
        insurer = msg.sender;
    }


    event PolicyCreated(uint policyId, address policyHolder, uint premium, uint coverageAmount);
    event PremiumPaid(uint policyId, address policyHolder);
    event ClaimSubmitted(uint policyId);
    event ClaimApproved(uint policyId);
    event PayoutDone(uint policyId, uint amount);
    event FundsDeposited(address from, uint amount);


    modifier onlyInsurer() {
        require(msg.sender == insurer, "Only insurer allowed");
        _;
    }

    modifier validPolicy(uint _policyId) {
        require(_policyId > 0 && _policyId <= policyCounter, "Invalid policy ID");
        _;
    }


    function fundContract() external payable onlyInsurer {
        require(msg.value > 0, "Must send ETH");
        emit FundsDeposited(msg.sender, msg.value);
    }

    function createPolicy(address _policyHolder, uint _premium, uint _coverageAmount) 
    public onlyInsurer {
        require(_policyHolder != address(0), "Invalid address");
        require(_premium > 0, "Premium must be > 0");
        require(_coverageAmount > 0, "Coverage must be > 0");

        policyCounter++;

        policies[policyCounter] = Policy({
            policyHolder: _policyHolder,
            premium: _premium,
            coverageAmount: _coverageAmount,
            isClaimed: false,
            isClaimApproved: false,
            premiumPaid: false,
            payoutDone: false
    });

        emit PolicyCreated(policyCounter, _policyHolder, _premium, _coverageAmount);
    }

    function payPremium(uint _policyId) external payable validPolicy(_policyId) {
        Policy storage policy = policies[_policyId];

        require(msg.sender == policy.policyHolder, "Only policy holder");
        require(!policy.premiumPaid, "Premium already paid");
        require(msg.value == policy.premium, "Incorrect premium");

        policy.premiumPaid = true;

        emit PremiumPaid(_policyId, msg.sender);
    }

    function submitClaim(uint _policyId) external validPolicy(_policyId) {
        Policy storage policy = policies[_policyId];

        require(msg.sender == policy.policyHolder, "Only policy holder");
        require(policy.premiumPaid, "Premium not paid");
        require(!policy.isClaimed, "Already claimed");

        policy.isClaimed = true;

        emit ClaimSubmitted(_policyId);
    }

    function approveClaim(uint _policyId) external onlyInsurer validPolicy(_policyId) {
        Policy storage policy = policies[_policyId];

        require(policy.isClaimed, "No claim submitted");
        require(!policy.isClaimApproved, "Already approved");

        policy.isClaimApproved = true;

        emit ClaimApproved(_policyId);
    }

    function claimPayout(uint _policyId) external validPolicy(_policyId) {
        Policy storage policy = policies[_policyId];

        require(msg.sender == policy.policyHolder, "Only policy holder");
        require(policy.isClaimApproved, "Claim not approved");
        require(!policy.payoutDone, "Already paid");

        uint amount = policy.coverageAmount;

        require(address(this).balance >= amount, "Insufficient contract funds");

        policy.payoutDone = true;

        (bool success, ) = payable(policy.policyHolder).call{value: amount}("");
        require(success, "Transfer failed");

        emit PayoutDone(_policyId, amount);
    }

    function policyDetails(uint _policyId) external view validPolicy(_policyId) returns (Policy memory) {
        return policies[_policyId];
    }

    function getContractBalance() external view returns (uint) {
        return address(this).balance;
    }

}