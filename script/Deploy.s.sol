// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Script, console} from "forge-std/Script.sol";
import {PayLink} from "../src/PayLink.sol";

/// @notice Deploy PayLink pointing at the official tUSD8 on QDay Aevum.
/// Usage:
///   forge script script/Deploy.s.sol --rpc-url aevum --broadcast \
///     --private-key $PRIVATE_KEY
contract Deploy is Script {
    /// @dev Official tUSD8 on QDay Aevum testnet (chain 44005), per qday.io
    ///      official-links page and wiki.qday.info FAQ §3.8.
    address constant TUSD8 = 0x456569838f1d43009A91ebA4263147Afd7233483;

    function run() external returns (PayLink paylink) {
        vm.startBroadcast();
        paylink = new PayLink(TUSD8);
        vm.stopBroadcast();
        console.log("PayLink deployed:", address(paylink));
    }
}
