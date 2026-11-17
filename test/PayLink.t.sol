// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Test} from "forge-std/Test.sol";
import {PayLink, IERC20} from "../src/PayLink.sol";

/// @dev Minimal 6-decimal ERC-20 mock standing in for tUSD8 in tests.
contract MockUSD8 is IERC20 {
    string public name = "Mock tUSD8";
    string public symbol = "tUSD8";
    uint8 public decimals = 6;

    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;

    function mint(address to, uint256 amount) external {
        balanceOf[to] += amount;
    }

    function approve(address spender, uint256 amount) external returns (bool) {
        allowance[msg.sender][spender] = amount;
        return true;
    }

    function transferFrom(address from, address to, uint256 amount) external returns (bool) {
        require(balanceOf[from] >= amount, "balance");
        require(allowance[from][msg.sender] >= amount, "allowance");
        allowance[from][msg.sender] -= amount;
        balanceOf[from] -= amount;
        balanceOf[to] += amount;
        return true;
    }
}

contract PayLinkTest is Test {
    MockUSD8 token;
    PayLink paylink;
    address merchant = address(0xA11CE);
    address payer = address(0xB0B);

    function setUp() public {
        token = new MockUSD8();
        paylink = new PayLink(address(token));
        token.mint(payer, 1_000e6);
    }

    function test_CreateAndPay() public {
        vm.prank(merchant);
        uint256 id = paylink.createRequest(25e6, "Invoice #1");

        vm.startPrank(payer);
        token.approve(address(paylink), 25e6);
        paylink.pay(id);
        vm.stopPrank();

        assertEq(token.balanceOf(merchant), 25e6);
        PayLink.Request memory r = paylink.getRequest(id);
        assertTrue(r.paid);
        assertEq(r.payer, payer);
    }

    function test_CancelOnlyByMerchant() public {
        vm.prank(merchant);
        uint256 id = paylink.createRequest(10e6, "test");

        vm.prank(payer);
        vm.expectRevert(PayLink.NotMerchant.selector);
        paylink.cancel(id);

        vm.prank(merchant);
        paylink.cancel(id);

        vm.startPrank(payer);
        token.approve(address(paylink), 10e6);
        vm.expectRevert(PayLink.AlreadyCancelled.selector);
        paylink.pay(id);
        vm.stopPrank();
    }

    function test_DoublePayReverts() public {
        vm.prank(merchant);
        uint256 id = paylink.createRequest(5e6, "once only");

        vm.startPrank(payer);
        token.approve(address(paylink), 10e6);
        paylink.pay(id);
        vm.expectRevert(PayLink.AlreadyPaid.selector);
        paylink.pay(id);
        vm.stopPrank();
    }
}
