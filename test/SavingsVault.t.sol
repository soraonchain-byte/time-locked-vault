// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/SavingsVault.sol"; // Pastikan path dan nama file src sesuai

contract SavingsVaultTest is Test {
    SavingsVault public vault;
    address public owner = address(0x123);
    uint256 public initialUnlockTime;

    function setUp() public {
        initialUnlockTime = block.timestamp + 1 hours;
        // Deploy dengan nama kontrak baru
        vm.prank(owner);
        vault = new SavingsVault(initialUnlockTime);
    }

    // 1. Test Deposit - Memastikan fungsi payable berjalan
    function testDeposit() public {
        uint256 depositAmount = 1 ether;
        vm.deal(address(0xABC), depositAmount);
        
        vm.prank(address(0xABC));
        vault.deposit{value: depositAmount}();
        
        assertEq(address(vault).balance, depositAmount);
    }

    // 2. Test Withdraw Gagal (Masih Terkunci)
    function testWithdrawEarlyShouldRevert() public {
        vm.deal(address(vault), 1 ether);
        
        vm.prank(owner);
        // Memastikan revert menggunakan Custom Error FundsLocked()
        vm.expectRevert(SavingsVault.FundsLocked.selector);
        vault.withdraw();
    }

    // 3. Test Withdraw Sukses (Waktu Terlewati)
    function testWithdrawAfterTime() public {
        uint256 amount = 1 ether;
        vm.deal(address(vault), amount);
        uint256 ownerInitialBalance = owner.balance;

        // Manipulasi waktu ke masa depan
        vm.warp(initialUnlockTime + 1);
        
        vm.prank(owner);
        vault.withdraw();

        assertEq(address(vault).balance, 0);
        assertEq(owner.balance, ownerInitialBalance + amount);
    }

    // 4. Test Extend Lock (Tambah Waktu)
    function testExtendLock() public {
        uint256 newTime = initialUnlockTime + 2 hours;
        
        vm.prank(owner);
        vault.extendLock(newTime);
        
        assertEq(vault.unlockTime(), newTime);
    }

    // 5. Test Gagal Extend (Waktu lebih pendek)
    function testExtendLockFailIfShorter() public {
        uint256 badTime = initialUnlockTime - 10 minutes;
        
        vm.prank(owner);
        vm.expectRevert("New time must be greater than current unlock time");
        vault.extendLock(badTime);
    }
}