// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract SavingsVault {
    error FundsLocked();
    error NotOwner();

    address public owner;
    uint256 public unlockTime;

    event Deposit(address indexed sender, uint256 amount);
    event Withdrawal(uint256 amount, uint256 timestamp);

    modifier onlyOwner() {
        if (msg.sender != owner) revert NotOwner();
        _;
    }

    constructor(uint256 _unlockTime) {
        require(_unlockTime > block.timestamp, "Unlock time must be in the future");
        owner = msg.sender;
        unlockTime = _unlockTime;
    }

    function deposit() public payable {
        emit Deposit(msg.sender, msg.value);
    }

    function extendLock(uint256 newTime) public onlyOwner {
        require(newTime > unlockTime, "New time must be greater than current unlock time");
        unlockTime = newTime;
    }

    function withdraw() public onlyOwner {
        if (block.timestamp < unlockTime) revert FundsLocked();
        
        uint256 amount = address(this).balance;
        emit Withdrawal(amount, block.timestamp);

        (bool success, ) = owner.call{value: amount}("");
        require(success, "Transfer failed");
    }

    receive() external payable {
        deposit();
    }
}