// PRS.sol
// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

import "./TimeUnit.sol";
import "./CommitReveal.sol";

contract RPS {
    uint public numPlayer = 0;
    uint public reward = 0;
    mapping (address => uint) public player_choice; // 0 - Rock, 1 - Paper , 2 - Scissors , 3 - Lizard , 4 - Spork
    mapping(address => bool) public player_not_played;
    address[] public players;

    uint public numInput = 0;

    CommitReveal public commitReveal = new CommitReveal();
    TimeUnit public timeunit = new TimeUnit();

    constructor() {
        commitReveal = new CommitReveal();
    }

    function addPlayer() public payable {
        require(msg.sender == 0x5B38Da6a701c568545dCfcB03FcB875f56beddC4 ||
                msg.sender == 0xAb8483F64d9C6d1EcF9b849Ae677dD3315835cb2 ||
                msg.sender == 0x4B20993Bc481177ec7E8f571ceCaE8A9e22C02db ||
                msg.sender == 0x78731D3Ca6b7E34aC0F824c42a7cC18A495cabaB );
        require(numPlayer < 2);
        if (numPlayer == 0) {
            timeunit.setStartTime();
        }else if(numPlayer > 0) {
            require(msg.sender != players[0]);
        }
        require(msg.value == 1 ether);
        reward += msg.value;
        player_not_played[msg.sender] = true;
        players.push(msg.sender);
        numPlayer++;
    }

    modifier isPlayers() {
        require(msg.sender == players[0] || msg.sender == players[1], "Not a valid player");
        _;
    }

    function commitMove(bytes32 _commitment, uint256 _choice, string memory _salt) external isPlayers {
        commitReveal.commitMove(msg.sender, _commitment, _choice, _salt);
    }

    function input(uint256 choice) external isPlayers {
        require(player_not_played[msg.sender], "Already revealed");
        require(choice == 0 ||
                choice == 1 ||
                choice == 2 ||
                choice == 3 ||
                choice == 4,
                "Invalid Choice"
        );
        require(commitReveal.reveal(msg.sender), "Invalid reveal");
        player_choice[msg.sender] = choice;
        player_not_played[msg.sender] = false;
        numInput++;

        if (numInput == 2) {
            _checkWinnerAndPay();
        }
    }

    function getHash(uint256 choice, string memory salt) public view returns (bytes32) {
        return commitReveal.getHash(choice, salt);
    }

    function forceGame() public payable {
        require(numPlayer == 2);
        require(player_not_played[msg.sender] == false);
        require(timeunit.elapsedSeconds() > 600);
        payable(players[0]).transfer(reward/2);
        payable(players[1]).transfer(reward/2);
        numPlayer = 0;
        reward = 0;
        numInput = 0;
        delete players;
    }

    function Callback() public payable {
        require(numPlayer == 1);
        require(timeunit.elapsedSeconds() > 300);
        if (timeunit.elapsedSeconds() > 300) {
            payable(players[0]).transfer(reward);
        }
        numPlayer = 0;
        reward = 0;
        numInput = 0;
        delete players;
    }

    function _checkWinnerAndPay() private {
        uint256 p0Choice = player_choice[players[0]];
        uint256 p1Choice = player_choice[players[1]];
        address payable account0 = payable(players[0]);
        address payable account1 = payable(players[1]);

        if ((p0Choice + 1) % 5 == p1Choice || (p0Choice + 3) % 5 == p1Choice) {
            account1.transfer(reward);
        } else if ((p1Choice + 1) % 5 == p0Choice || (p1Choice + 3) % 5 == p0Choice) {
            account0.transfer(reward);
        } else {
            account0.transfer(reward / 2);
            account1.transfer(reward / 2);
        }
        resetGame();
    }

    function resetGame() internal {
        delete player_choice[players[0]];
        delete player_choice[players[1]];
        numPlayer = 0;
        reward = 0;
        numInput = 0;
        commitReveal.resetCommit(players[0], players[1]); // เรียกใช้ resetCommit
        delete players;
    }

}