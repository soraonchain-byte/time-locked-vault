// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/TimeLockedVault.sol";

contract TimeLockedVaultTest is Test {
    TimeLockedVault public vault;
    address public owner = address(1);
    uint256 public unlockTime;

    function setUp() public {
        unlockTime = block.timestamp + 1 hours;
        vm.prank(owner);
        vault = new TimeLockedVault(unlockTime);
    }

    function testDeposit() public {
        vm.deal(address(2), 1 ether);
        vm.prank(address(2));
        vault.deposit{value: 1 ether}();
        assertEq(address(vault).balance, 1 ether);
    }

    function testFailWithdrawEarly() public {
        vm.deal(address(vault), 1 ether);
        vm.prank(owner);
        vault.withdraw(); // Akan revert karena waktu belum lewat
    }

    function testWithdrawAfterTime() public {
        vm.deal(address(vault), 1 ether);
        vm.warp(unlockTime + 1); // Lompat ke masa depan
        vm.prank(owner);
        vault.withdraw();
        assertEq(address(vault).balance, 0);
    }

    function testExtendLock() public {
        uint256 newTime = unlockTime + 1 hours;
        vm.prank(owner);
        vault.extendLock(newTime);
        assertEq(vault.unlockTime(), newTime);
    }
}