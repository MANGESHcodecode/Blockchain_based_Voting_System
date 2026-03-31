// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract Voting {
    address public authority;
    bool public electionActive;
    uint256 public electionEndTime;
    
    struct Candidate {
        string name;
        uint256 voteCount;
    }
    
    Candidate[] public candidates;
    
    mapping(address => bool) public isRegisteredVoter;
    mapping(address => bool) public hasVoted;
    
    uint256 private _totalVotes;
    
    // Store encrypted ballots and commitments
    struct VoteData {
        bytes encryptedBallot;
        bytes32 commitment;
    }
    mapping(address => VoteData) public votes;

    event VoteCast(address indexed voter, bytes encryptedBallot);

    modifier onlyAuthority() {
        require(msg.sender == authority, "Only authority can perform this action");
        _;
    }
    
    constructor() {
        authority = msg.sender;
    }
    
    function addCandidate(string memory name) public onlyAuthority {
        require(!electionActive, "Cannot add candidate during election");
        candidates.push(Candidate(name, 0));
    }
    
    function registerVoter(address voter) public onlyAuthority {
        require(!electionActive, "Cannot register during election");
        isRegisteredVoter[voter] = true;
    }
    
    function startElection(uint256 durationSeconds) public onlyAuthority {
        require(!electionActive, "Election already active");
        require(candidates.length > 0, "No candidates");
        electionActive = true;
        electionEndTime = block.timestamp + durationSeconds;
    }
    
    function endElection() public onlyAuthority {
        require(electionActive, "Election not active");
        electionActive = false;
    }
    
    function publishResults(uint256[] memory voteCounts) public onlyAuthority {
        require(!electionActive, "Election must be over");
        require(voteCounts.length == candidates.length, "Invalid array size");
        for(uint i = 0; i < candidates.length; i++) {
            candidates[i].voteCount = voteCounts[i];
        }
    }
    
    function castVote(bytes memory encryptedBallot, bytes32 commitment) public {
        require(electionActive, "Election not active");
        require(block.timestamp <= electionEndTime, "Election has ended");
        require(isRegisteredVoter[msg.sender], "Not a registered voter");
        require(!hasVoted[msg.sender], "Already voted");
        
        hasVoted[msg.sender] = true;
        votes[msg.sender] = VoteData(encryptedBallot, commitment);
        _totalVotes++;
        emit VoteCast(msg.sender, encryptedBallot);
    }
    
    function getCandidates() public view returns (Candidate[] memory) {
        return candidates;
    }
    
    function getTotalVotes() public view returns (uint256) {
        return _totalVotes;
    }
}
