// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

import "./interfaces/IERC20.sol";

contract DegenBaseEpochs2 is ReentrancyGuard, Ownable {
    event AirdropUser(
        uint256 amount,
        uint256 points,
        IERC20 token,
        uint256 time,
        bool isSent
    );

    mapping(address => bool) public isChecked;
    mapping(address => bool) public isSent;
    mapping(address => uint256) public totalPoints;

    uint256 public count;
    uint256 public airdropCounts;

    IERC20 public airdropToken;
    uint256 public _multiplier = 5;
    uint256 public airdropAmount;

   

    function tokenBalance(address _t) public view returns (uint256) {
        uint256 _b = IERC20(_t).balanceOf(address(this));
        return _b;
    }


    function addMultipleToListed(address user, uint256 t) public onlyOwner {
        require(t > 0, "!zero points");
        require(isChecked[user] == false, "!already drafted");
        isChecked[user] = true;
        isSent[user] = false;
        totalPoints[user] = t;
        count += 1;
    }

    function removeFromListed(address _u) public onlyOwner {
        isChecked[_u] = false;
    }

    function setAirdropAmount(uint256 amount) public onlyOwner {
        airdropAmount = amount;
    }

    function setMultiplier(uint256 amount) public onlyOwner {
        _multiplier = amount;
    }

    function setToken(IERC20 tokenAddress) public onlyOwner {
        airdropToken = tokenAddress;
    }

    function checkStatus(address user) public view returns (bool, bool) {
        return (isChecked[user], isSent[user]);
    }

    function estimateAmount(address _u) public view returns (uint256) {
        return (totalPoints[_u] * _multiplier) * airdropAmount;
    }

    function getUserPoints(address _u) public view returns (uint256) {
        return totalPoints[_u];
    }

    function updateStatus(address _u) private {
        isSent[_u] = true;
    }

    function treasuryCall(address _t, uint256 amount) public onlyOwner {
        require(IERC20(_t).balanceOf(address(this)) >= amount, "!balance");
        IERC20(_t).transfer(msg.sender, amount);
    }

    function airdrop(address[] memory list) public onlyOwner {
        for (uint256 i = 0; i < list.length; i++) {
            uint256 pts = getUserPoints(list[i]);

            (bool isWL, bool isDistributed) = checkStatus(list[i]);

            if (isDistributed == false && isWL == true) {
                uint256 _a = estimateAmount(list[i]);
                IERC20(airdropToken).transfer(list[i], _a);
                updateStatus(list[i]);
                airdropCounts += 1;
                emit AirdropUser(
                    _a,
                    pts,
                    airdropToken,
                    block.timestamp,
                    isDistributed
                );
            }
        }
    }
}
