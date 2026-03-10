// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract TimeLockedVault {
    // --- Custom Errors ---
    error FundsLocked(uint256 unlockTime);
    error NotOwner();
    error InvalidNewTime(uint256 currentUnlockTime);
    error InvalidInitialTime();

    // --- State Variables ---
    address public immutable owner;
    uint256 public unlockTime;

    // --- Events ---
    event Deposit(address indexed sender, uint256 amount);
    event Withdrawal(uint256 amount, uint256 timestamp);
    event LockExtended(uint256 newUnlockTime);

    // --- Modifiers ---
    modifier onlyOwner() {
        if (msg.sender != owner) revert NotOwner();
        _;
    }

    // --- Constructor ---
    // Memastikan tidak bisa deploy dengan waktu di masa lalu
    constructor(uint256 _unlockTime) {
        if (_unlockTime <= block.timestamp) revert InvalidInitialTime();
        owner = msg.sender;
        unlockTime = _unlockTime;
    }

    // --- Deposit Logic ---
    function deposit() public payable {
        emit Deposit(msg.sender, msg.value);
    }

    // --- Extension Logic ---
    // Update hanya jika waktu baru > waktu sekarang (tidak bisa dikurangi)
    function extendLock(uint256 _newTime) public onlyOwner {
        if (_newTime <= unlockTime) revert InvalidNewTime(unlockTime);
        unlockTime = _newTime;
        emit LockExtended(_newTime);
    }

    // --- Withdrawal Logic (CEI Pattern) ---
    function withdraw() public onlyOwner {
        // [CHECK]
        if (block.timestamp < unlockTime) revert FundsLocked(unlockTime);
        
        uint256 amount = address(this).balance;
        
        // [EFFECT]
        emit Withdrawal(amount, block.timestamp);
        
        // [INTERACTION]
        (bool success, ) = owner.call{value: amount}("");
        require(success, "Transfer failed");
    }

    // Menerima ETH langsung
    receive() external payable {
        deposit();
    }
}