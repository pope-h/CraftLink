// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script} from "forge-std/Script.sol";
import {console} from "forge-std/console.sol";
import {Registry} from "../src/Registry.sol";
import {CraftLinkToken} from "../src/CraftLinkToken.sol";
import {PaymentProcessor} from "../src/PaymentProcessor.sol";
import {GigMarketplace} from "../src/GigMarketplace.sol";
import {ReviewSystem} from "../src/ReviewSystem.sol";
import {ChatSystem} from "../src/ChatSystem.sol";

contract DeployScript is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        Registry registry = new Registry();
        CraftLinkToken craftLinkToken = new CraftLinkToken();
        PaymentProcessor paymentProcessor = new PaymentProcessor(address(craftLinkToken));
        GigMarketplace gigMarketplace = new GigMarketplace(address(registry), address(paymentProcessor));
        ReviewSystem reviewSystem = new ReviewSystem(address(registry), address(gigMarketplace));
        ChatSystem chatSystem = new ChatSystem(address(gigMarketplace));

        console.log("Registry deployed at:", address(registry));
        console.log("CraftLinkToken deployed at:", address(craftLinkToken));
        console.log("PaymentProcessor deployed at:", address(paymentProcessor));
        console.log("GigMarketplace deployed at:", address(gigMarketplace));
        console.log("ReviewSystem deployed at:", address(reviewSystem));
        console.log("ChatSystem deployed at:", address(chatSystem));

        vm.stopBroadcast();
    }
}
