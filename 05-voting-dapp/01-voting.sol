// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;


contract VotingSystem {

    address public admin;

    struct Candidate {
        uint id;
        string name;
        uint voteCount;
    }

    mapping(uint => Candidate) public candidates;
    mapping(address => bool) public hasVoted;

    uint public candidatesCount = 0;
    uint public startTime;
    uint public endTime;

    
    event CandidateAdded(uint indexed candidateId, string name);
    event VoteCast(uint indexed candidateId);
    event Winner(string[] winners, uint votes);


    modifier adminOnly() {
        require(msg.sender == admin, "Must be Admin");
        _;
    }


    constructor(uint _durationInMinutes) {
        admin = msg.sender;

        startTime = block.timestamp;
        endTime = startTime + (_durationInMinutes * 1 minutes);

        // addCandidate("Bob");
        // addCandidate("Alice");
    }

    function addCandidate(string memory _name) private {
        candidatesCount++;
        candidates[candidatesCount] = Candidate(candidatesCount, _name, 0);
        emit CandidateAdded(candidatesCount, _name);
    }

    function vote(uint _candidateId) public {
        require(block.timestamp >= startTime && block.timestamp <= endTime, "Voting not active");
        require(!hasVoted[msg.sender], "Already voted");

        require(_candidateId > 0 && _candidateId <= candidatesCount, "Invalid candidate");

        hasVoted[msg.sender] = true;
        candidates[_candidateId].voteCount++;

        emit VoteCast(_candidateId);
    }

    function getAllCandidates() public view returns (Candidate [] memory) {
        Candidate[] memory candidateArray = new Candidate[](candidatesCount);

        for (uint i = 1; i <= candidatesCount; i++) {
            candidateArray[i - 1] = candidates[i];
        }

        return candidateArray;
    }

    function _getLeader() internal view returns (uint [] memory winnerIds, uint maxVotes) {
        maxVotes = 0;
        uint winnerCount = 0;

        for (uint i = 1; i <= candidatesCount; i++) {
            if (candidates[i].voteCount > maxVotes) {
                maxVotes = candidates[i].voteCount;
            }
        }

        if (maxVotes == 0) {
            return (new uint[](0), 0);
        }

        for (uint i = 1; i <= candidatesCount; i++) {
            if (candidates[i].voteCount == maxVotes) {
                winnerCount++;
            }
        }

        winnerIds = new uint [] (winnerCount);
        uint index = 0;

        for (uint i = 1; i <= candidatesCount; i++) {
            if (candidates[i].voteCount == maxVotes) {
                winnerIds[index] = i;
                index++;
            }
        }
        
        return (winnerIds, maxVotes);
    }

    function getLeaderNames() public view returns (string[] memory leaderNames, uint) {
        (uint[] memory leaderIds, uint votes)  = _getLeader();

       leaderNames = new string[] (leaderIds.length);

        for (uint i = 0; i < leaderIds.length; i++) {
            leaderNames[i] = candidates[leaderIds[i]].name;
        }

        return (leaderNames, votes);
    }

    function getWinner() public view returns (string[] memory winnerNames, uint votes) {
        require(block.timestamp > endTime, "Voting has not yet closed!");
        (winnerNames, votes) = getLeaderNames();

        return (winnerNames, votes);
    }

    function announceWinner() public adminOnly returns (string[] memory winnerNames, uint votes) {
        require(block.timestamp > endTime, "Voting has not yet closed!");
        (winnerNames, votes) = getLeaderNames();

        emit Winner(winnerNames, votes);

        return (winnerNames, votes);
    }
}