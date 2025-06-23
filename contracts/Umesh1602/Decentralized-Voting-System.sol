
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

contract Project {
    struct Candidate {
        uint id;
        string name;
        uint voteCount;
    }
    
    struct Voter {
        bool isAuthorized;
        bool hasVoted;
        uint votedCandidateId;
    }
    
    address public owner;
    string public electionName;
    bool public votingOpen;
    
    mapping(address => Voter) public voters;
    mapping(uint => Candidate) public candidates;
    uint public candidatesCount;
    uint public totalVotes;
    
    event VoterAuthorized(address voter);
    event VoteCast(address voter, uint candidateId);
    event CandidateAdded(uint candidateId, string name);
    
    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can perform this action");
        _;
    }
    
    modifier onlyAuthorizedVoter() {
        require(voters[msg.sender].isAuthorized, "You are not authorized to vote");
        require(!voters[msg.sender].hasVoted, "You have already voted");
        _;
    }
    
    modifier votingMustBeOpen() {
        require(votingOpen, "Voting is not currently open");
        _;
    }
    
    constructor(string memory _electionName) {
        owner = msg.sender;
        electionName = _electionName;
        votingOpen = false;
    }
    
    // Core Function 1: Add candidates and manage voting process
    function addCandidate(string memory _name) public onlyOwner {
        require(!votingOpen, "Cannot add candidates while voting is open");
        require(bytes(_name).length > 0, "Candidate name cannot be empty");
        
        candidatesCount++;
        candidates[candidatesCount] = Candidate(candidatesCount, _name, 0);
        
        emit CandidateAdded(candidatesCount, _name);
    }
    
    function authorizeVoter(address _voter) public onlyOwner {
        require(!voters[_voter].isAuthorized, "Voter is already authorized");
        
        voters[_voter].isAuthorized = true;
        voters[_voter].hasVoted = false;
        
        emit VoterAuthorized(_voter);
    }
    
    function startVoting() public onlyOwner {
        require(candidatesCount > 0, "No candidates available");
        require(!votingOpen, "Voting is already open");
        
        votingOpen = true;
    }
    
    function endVoting() public onlyOwner {
        require(votingOpen, "Voting is not open");
        
        votingOpen = false;
    }
    
    // Core Function 2: Cast vote
    function vote(uint _candidateId) public onlyAuthorizedVoter votingMustBeOpen {
        require(_candidateId > 0 && _candidateId <= candidatesCount, "Invalid candidate ID");
        
        voters[msg.sender].hasVoted = true;
        voters[msg.sender].votedCandidateId = _candidateId;
        
        candidates[_candidateId].voteCount++;
        totalVotes++;
        
        emit VoteCast(msg.sender, _candidateId);
    }
    
    // Core Function 3: Get election results
    function getResults() public view returns (uint[] memory, string[] memory, uint[] memory) {
        uint[] memory candidateIds = new uint[](candidatesCount);
        string[] memory candidateNames = new string[](candidatesCount);
        uint[] memory voteCounts = new uint[](candidatesCount);
        
        for (uint i = 1; i <= candidatesCount; i++) {
            candidateIds[i-1] = candidates[i].id;
            candidateNames[i-1] = candidates[i].name;
            voteCounts[i-1] = candidates[i].voteCount;
        }
        
        return (candidateIds, candidateNames, voteCounts);
    }
    
    // Additional utility functions
    function getCandidate(uint _candidateId) public view returns (uint, string memory, uint) {
        require(_candidateId > 0 && _candidateId <= candidatesCount, "Invalid candidate ID");
        
        Candidate memory candidate = candidates[_candidateId];
        return (candidate.id, candidate.name, candidate.voteCount);
    }
    
    function getVoterStatus(address _voter) public view returns (bool, bool, uint) {
        Voter memory voter = voters[_voter];
        return (voter.isAuthorized, voter.hasVoted, voter.votedCandidateId);
    }
    
    function getWinner() public view returns (uint, string memory, uint) {
        require(candidatesCount > 0, "No candidates available");
        
        uint winningVoteCount = 0;
        uint winningCandidateId = 0;
        
        for (uint i = 1; i <= candidatesCount; i++) {
            if (candidates[i].voteCount > winningVoteCount) {
                winningVoteCount = candidates[i].voteCount;
                winningCandidateId = i;
            }
        }
        
        require(winningCandidateId > 0, "No winner found");
        
        return (candidates[winningCandidateId].id, 
                candidates[winningCandidateId].name, 
                candidates[winningCandidateId].voteCount);
    }
}
