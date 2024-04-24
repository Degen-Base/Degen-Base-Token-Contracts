// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";


contract DegenBaseToken is  ERC20("Degen Base", "DB") , Ownable{

    uint256 public immutable maxSupply = 1000000000000000000000000;    
    function mint(address _to, uint256 _amount) public onlyOwner {
        require(totalSupply() + _amount <= maxSupply, "mint: cannot exceed max supply");
        _mint(_to, _amount);
    }

}

