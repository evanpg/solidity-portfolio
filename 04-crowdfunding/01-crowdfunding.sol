// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";


contract CrowdFunding is ReentrancyGuard{

    mapping(address => uint) public contributors;
    address public manager;
    uint public minContribution;
    uint public deadLine;
    uint public target;
    uint public raisedAmount;
    uint public numContributors;

    struct Request {
        string description;
        address payable recipient;
        uint value;
        bool isCompleted;
        uint numVoters;
        mapping(address => bool) voters;
    }

    mapping(uint => Request) public requests;
    uint public numRequests;

    constructor(uint _target, uint _deadLine) {
        target = _target;
        deadLine = block.timestamp + _deadLine;
        minContribution = 100 wei;
        manager = msg.sender;
    }


    modifier onlyManager() {
        require(msg.sender == manager, "Only manager");
        _;
    }


    function getContractBalance() public view returns (uint) {
        return address(this).balance;
    }

    function createRequest(string memory _description, address payable _recipient, uint _value)
    public onlyManager {

        Request storage newRequest = requests[numRequests];
        numRequests++;

        newRequest.description = _description;
        newRequest.recipient = _recipient;
        newRequest.value = _value;
        newRequest.isCompleted = false;
        newRequest.numVoters = 0;
    }

    function sendEth() public payable {
        require(block.timestamp < deadLine, "Deadline passed");
        require(msg.value >= minContribution, "Minimum contribution not met");

        if (contributors[msg.sender] == 0) {
            numContributors++;
        }

        contributors[msg.sender] += msg.value;
        raisedAmount += msg.value;
    }

    function voteRequest(uint _requestNo) public {
        require(contributors[msg.sender] > 0, "Not a contributor");
        require(_requestNo < numRequests, "Invalid request");

        Request storage thisRequest = requests[_requestNo];

        require(!thisRequest.voters[msg.sender], "Already voted");

        thisRequest.voters[msg.sender] = true;
        thisRequest.numVoters++;
    }

    function payOutRecipientAddress(uint _requestNo) public nonReentrant onlyManager {
        require(raisedAmount >= target, "Target not met");
        require(_requestNo < numRequests, "Invalid request");

        Request storage thisRequest = requests[_requestNo];

        require(!thisRequest.isCompleted, "Already paid");
        require(thisRequest.numVoters > numContributors / 2, "Majority not reached");
        require(thisRequest.value <= address(this).balance, "Not enough funds");

        thisRequest.isCompleted = true;

        (bool success, ) = thisRequest.recipient.call{value: thisRequest.value}("");
        require(success, "Payment failed");
    }

    function refund() public nonReentrant {
        require(block.timestamp > deadLine && raisedAmount < target, "Refund not allowed");
        require(contributors[msg.sender] > 0, "No contribution");

        uint amount = contributors[msg.sender];
        contributors[msg.sender] = 0;
        raisedAmount -= amount;

        (bool success, ) = payable(msg.sender).call{value: amount}("");
        require(success, "Refund failed");
    }

}