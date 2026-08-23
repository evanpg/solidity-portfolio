// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

contract Lottery is ReentrancyGuard {

    address public admin;
    address [] public participants;

    constructor() {
        admin = msg.sender;
    }

    receive() external payable {
        require(msg.value == 0.1 ether, "Must send 0.1 ETH");
        participants.push(msg.sender);
    }

    function getBalance() public view returns (uint) {
        return address(this).balance;
    }

    function random() internal view returns (uint) {
        return uint(
            keccak256(
                abi.encodePacked(
                    block.prevrandao,
                    block.timestamp,
                    participants.length
                )
            )
        );
    }

    function pickWinner() external nonReentrant {
        require(msg.sender == admin, "Only admin");
        require(participants.length >= 2, "Not enough participants");

        uint index = random() % participants.length;
        address  winner = participants[index];

        uint prize = address(this).balance;

        (bool success, ) = winner.call{value: prize}("");
        require(success, "Transfer failed");

        delete participants;
    }
}