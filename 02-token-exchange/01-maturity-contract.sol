// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";


contract Trust is ReentrancyGuard {

    struct Kid {
        uint amount;
        uint maturity;
        string name;
        bool paid;
        bool cancelled;
        bool exists;
    }

    mapping(address => Kid) public kids;

    address public parent;

    event KidAdded(address kid, uint maturity, uint amount);
    event Withdrawn(address kid, uint amount);
    event KidRemoved(address kid, uint refundedAmount);

    constructor() {
        parent = msg.sender;
    } 


    function addKid(address kid, string memory name, uint timeToMaturity) 
    external payable {
        require(msg.sender == parent, "Must be parent to add kid");
        require(msg.value > 0, "Must send ETH");
        require(!kids[kid].exists, "kid already exists");

        kids[kid] = Kid({
            amount: msg.value,
            maturity: block.timestamp + timeToMaturity,
            paid: false,
            name: name,
            cancelled: false,
            exists: true
        });

        emit KidAdded(kid, kids[kid].maturity, msg.value);
    }

    function cancelKid(address kidAddress)
    external nonReentrant {
        require(msg.sender == parent, "Must be parent to cancel trust");

        Kid storage kid = kids[kidAddress];
        require(kid.exists, "kid doesn't exist");
        require(!kid.paid, "kid already paid");
        require(!kid.cancelled, "trust already cancelled");

        kid.cancelled = true;
        uint amount = kid.amount;
        kid.amount = 0;

        emit KidRemoved(kidAddress, amount);

        (bool success,) = payable(parent).call{value: amount}("");
        require(success, "refund failed");
    }

    function withdraw(address kidAddress) 
    external nonReentrant {
        require(msg.sender == kidAddress, "must be kid");
        
        Kid storage kid = kids[kidAddress];
        require(kid.exists, "kid doesn't exist");
        require(block.timestamp >= kid.maturity, "maturity not met");
        require(!kid.cancelled, "trust already cancelled");
        require(!kid.paid, "kid already paid");

        kid.paid = true;
        uint amount = kid.amount;
        kid.amount = 0;

        emit Withdrawn(msg.sender, amount);

        (bool success,) = payable(kidAddress).call{value: amount}("");
        require(success, "payment failed");
    }
}
