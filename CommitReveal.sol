// CommitReveal.sol
// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

contract CommitReveal {
    struct Commitment {
        bytes32 commit;
        uint256 choice;
        string salt;
    }

    mapping(address => Commitment) public commits;

    function commitMove(address player, bytes32 _commitment, uint256 _choice, string memory _salt) public {
        require(commits[player].commit == bytes32(0), "Already committed");
        commits[player] = Commitment(_commitment, _choice, _salt);
    }

    function reveal(address player) public view returns (bool) {
        require(commits[player].commit != bytes32(0), "CommitReveal::reveal: No commit found");
        require(keccak256(abi.encode(commits[player].choice, commits[player].salt)) == commits[player].commit, "CommitReveal::reveal: Revealed hash does not match commit");
        return true;
    }

    function getHash(uint256 choice, string memory salt) public pure returns (bytes32) {
        return keccak256(abi.encode(choice, salt));
    }

    function getCommitment(address player) public view returns (bytes32) {
        return commits[player].commit;
    }

    function resetCommit(address player1, address player2) public {
        delete commits[player1];
        delete commits[player2];
    }
}