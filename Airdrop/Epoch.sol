// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

import "./interfaces/IERC20.sol";

contract DegenBaseEpochs is ReentrancyGuard, Ownable {
    event AirdropUser(
        uint256 amount,
        uint256 points,
        IERC20 token,
        uint256 time,
        bool isSent
    );

    mapping(address => bool) isChecked;
    mapping(address => bool) isSent;
    mapping(address => uint256) totalPoints;

    uint256 public count;
    uint256 public airdropCounts;

    IERC20 public airdropToken;
    uint256 public _multiplier = 5;
    uint256 public airdropAmount;

    struct EpochData {
        bool isWhitelisted;
        bool isSent;
        uint256 totalPoints;
    }

    mapping(address => EpochData) public candidate;

    function tokenBalance(address _t) public view returns (uint256) {
        uint256 _b = IERC20(_t).balanceOf(address(this));
        return _b;
    }

    function addToListed(address _u, uint256 points) public onlyOwner {
        require(points > 0, "!zero points");
        require(isChecked[_u] == false, "!already drafted");

        EpochData storage data = candidate[_u];
        data.isWhitelisted = true;
        data.totalPoints = points;
        isChecked[_u] = true;
        count += 1;
    }

    function removeFromListed(address _u) public onlyOwner {
        EpochData storage data = candidate[_u];
        require(data.isWhitelisted == true, "!not listed");
        delete candidate[_u];
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
        EpochData memory data = candidate[user];
        return (data.isWhitelisted, data.isSent);
    }

    function estimateAmount(address _u) public view returns (uint256) {
        EpochData memory data = candidate[_u];
        return (data.totalPoints * _multiplier) * airdropAmount;
    }

    function getUserPoints(address _u) public view returns (uint256) {
        EpochData memory data = candidate[_u];
        return data.totalPoints;
    }

    function updateStatus(address _u) private {
        EpochData storage data = candidate[_u];
        data.isSent = true;
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
