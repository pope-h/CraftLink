// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract CraftLinkToken is ERC20, Ownable {
    uint256 public constant CLAIM_AMOUNT = 1000 * 10 ** 18;
    mapping(address => bool) public hasClaimed;

    constructor() ERC20("CraftLink Token", "CLT") Ownable(msg.sender) {
        // _mint(msg.sender, initialSupply * 10**18);
    }

    function claim() external {
        require(!hasClaimed[msg.sender], "Address has already claimed tokens");

        hasClaimed[msg.sender] = true;
        _mint(msg.sender, CLAIM_AMOUNT);
    }

    function mint(address to, uint256 amount) external onlyOwner {
        _mint(to, amount);
    }

    function burn(uint256 amount) external {
        _burn(msg.sender, amount);
    }
}