// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

import "./libraries/SafeERC20.sol";
import "./libraries/Address.sol";
import "./interfaces/IERC20.sol";

contract DegenPresale is ReentrancyGuard, Ownable {
    using SafeERC20 for IERC20;

    address public treasury;
    address public liquidity;

    IERC20 public paymentToken;
    IERC20 public currency;

    mapping(address => uint256) public minimumAmount;
    mapping(address => uint256) public maxAmount;

    mapping(address => bool) public isCurrency;
    mapping(address => bool) public isPaymentToken;

    mapping(address => uint256) public balance;
    mapping(address => uint256) public investedAmount;

    mapping(address => bool) public isInvestor;

    uint256 public unlockTime;

    event Presale(
        address indexed user,
        address indexed currency,
        uint256 currentAmount,
        uint256 tokenPurchased,
        uint256 time
    );

    event ClaimCurrency(
        address indexed user,
        address indexed currency,
        uint256 amount,
        uint256 invested,
        uint256 time
    );

    function setTreasury(address _t) external onlyOwner {
        treasury = _t;
    }

    function setLiquidity(address _l) external onlyOwner {
        liquidity = _l;
    }

    function setPaymentToken(address _token) external onlyOwner {
        require(isPaymentToken[_token] == false, "already set token");
        paymentToken = IERC20(_token);
        isPaymentToken[_token] = true;
    }

    function removePaymentToken(address _token) external onlyOwner {
        require(isPaymentToken[_token] == true, "!not listed");
        paymentToken = IERC20(address(0));
        isPaymentToken[_token] = false;
    }

    function setCurrency(address _currency) external onlyOwner {
        currency = IERC20(_currency);
        isCurrency[_currency] = true;
    }

    function delistCurrency(address _currency) external onlyOwner {
        isCurrency[_currency] = false;
        currency = IERC20(address(0));
    }

    function setMinimumAmount(address _a, uint256 _t) external onlyOwner {
        minimumAmount[_a] = _t;
    }

    function setMaxAmount(address _a, uint256 _t) external onlyOwner {
        maxAmount[_a] = _t;
    }

    function getCurrencyStatus(address _u) external view returns (bool) {
        return isCurrency[_u];
    }

    function getPaymentTokenStatus(address _t) external view returns (bool) {
        return isPaymentToken[_t];
    }

    function getBalance(address _u) external view returns (uint256) {
        return balance[_u];
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

    function getMinimumAmount(address token) external view returns (uint256) {
        require(isPaymentToken[token] == true, "!token not listed");
        return minimumAmount[token];
    }

    function getMaxAmount(address token) external view returns (uint256) {
        require(isPaymentToken[token] == true, "!token not listed");
        return maxAmount[token];
    }

    function purchaseToken(
        address _token,
        uint256 amount
    ) external nonReentrant {
        require(isPaymentToken[_token] == true, "!not listed");
        require(amount >= minimumAmount[_token], "!min amount");

        require(maxAmount[_token] >= amount, "!exceed max amount");
        uint256 allocated = (amount / minimumAmount[_token]) *
            10 ** IERC20(_token).decimals();
        investedAmount[msg.sender] += amount;

        require(
            maxAmount[_token] >= investedAmount[msg.sender],
            "!max cap per wallet exceeded"
        );

        require(msg.sender != address(0), "!null");

        IERC20(paymentToken).safeTransferFrom(
            msg.sender,
            address(this),
            amount
        );

        balance[msg.sender] += allocated;
        isInvestor[msg.sender] = true;

        emit Presale(msg.sender, _token, amount, allocated, block.timestamp);
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
        address _user = msg.sender;
        require(isInvestor[msg.sender] == true, "!investor");
        require(balance[msg.sender] > 0, "!user did not purchase");
        require(block.timestamp >= unlockTime, "!lock time ");
        require(
            IERC20(currency).balanceOf(address(this)) >= balance[msg.sender],
            "!not enough balance"
        );

        IERC20(currency).safeTransfer(msg.sender, balance[_user]);
        balance[msg.sender] = 0;
        isInvestor[msg.sender] = false;
        emit ClaimCurrency(
            msg.sender,
            address(currency),
            balance[_user],
            investedAmount[_user],
            block.timestamp
        );
    }

    function treasuryCall(
        address _t,
        uint256 amount
    ) public nonReentrant onlyOwner {
        require(isPaymentToken[_t] == true, "!not token");
        require(treasury != address(0), "!treasury");
        IERC20(_t).safeTransfer(msg.sender, amount);
    }
    

    function liquidityCall(
        address _t,
        uint256 amount
    ) public nonReentrant onlyOwner {
        require(isPaymentToken[_t] == true, "!not token");
        require(liquidity != address(0), "!liquidity");
        IERC20(_t).safeTransfer(liquidity, amount);
    }
}
