// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

import "./libraries/SafeERC20.sol";
import "./libraries/Address.sol";
import "./presale.sol";

contract PresaleDistribution is ReentrancyGuard, Ownable {
    using SafeERC20 for IERC20;

    address public treasury;
    address public liquidity;

    IERC20 public currency;

    mapping(address => bool) public isCurrency;

    mapping(address => bool) public isInvestor;

    uint256 public unlockTime;

    mapping(address => bool) public isClaimed;

    DegenPresale public presaleContract;

    event ClaimCurrency(
        address indexed user,
        address indexed currency,
        uint256 amount,
        uint256 time
    );

    function link(address _s) external onlyOwner {
        presaleContract = DegenPresale(_s);
    }

    function setCurrency(address _currency) external onlyOwner {
        currency = IERC20(_currency);
        isCurrency[_currency] = true;
    }

    function delistCurrency(address _currency) external onlyOwner {
        isCurrency[_currency] = false;
        currency = IERC20(address(0));
    }

    function getCurrencyStatus(address _u) external view returns (bool) {
        return isCurrency[_u];
    }

    function updateUnlockTime(uint256 _unlockTime) external onlyOwner {
        require(
            _unlockTime >= block.timestamp,
            "Unlock time should be in the future"
        );
        unlockTime = _unlockTime;
    }

    function getCurrencyBalance(
        address token
    ) public view returns (uint256 _b) {
        _b = IERC20(token).balanceOf(address(this));
        return _b;
    }

    function checkPresaleBalance(address _u) public view returns (uint256) {
        uint256 amount = presaleContract.getBalance(_u);
        return amount;
    }

    function getPresaleBalance() public view returns (uint256) {
        uint256 amount = presaleContract.getBalance(msg.sender);
        return amount;
    }

    function checkIfInvested() public view returns (bool) {
        if (presaleContract.isInvestor(msg.sender) == true) {
            return true;
        } else {
            return false;
        }
    }

    function checkUnlockTime() external view returns (bool) {
        if (block.timestamp >= unlockTime) {
            return true;
        } else {
            return false;
        }
    }

    // withdraw $DB token
    function withdrawPresale() public nonReentrant {
        require(isClaimed[msg.sender] == false, "user has  claimed");
        require(getPresaleBalance() > 0, "!user did not purchase");
        require(block.timestamp >= unlockTime, "!lock time ");
        require(
            IERC20(currency).balanceOf(address(this)) >= getPresaleBalance(),
            "!not enough balance"
        );

        IERC20(currency).safeTransfer(msg.sender, getPresaleBalance());
        isClaimed[msg.sender] = true;

        emit ClaimCurrency(
            msg.sender,
            address(currency),
            getPresaleBalance(),
            block.timestamp
        );
    }

    function treasuryCall(
        address _t,
        uint256 amount
    ) public nonReentrant onlyOwner {
        require(treasury != address(0), "!treasury");
        IERC20(_t).safeTransfer(msg.sender, amount);
    }
}
