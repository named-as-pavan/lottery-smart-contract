// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import {Script, console2 as console} from "../lib/forge-std/src/Script.sol";
import {Raffle} from "../src/Raffle.sol";
import {HelperConfig} from "./HelperConfig.s.sol";
import {CreateSubscription, FundSubscription, AddConsumer} from "../script/Interactions.s.sol";

contract DeployRaffle is Script {
    function run() external {
        deployContract();
    }

    function deployContract() public returns (Raffle, HelperConfig) {
        HelperConfig helperConfig = new HelperConfig();
        // local -. deploy mocs, get local config
        // sepolia -. get sepolia config
        HelperConfig.NetworkConfig memory config = helperConfig.getConfig();

        if (config.subscriptionId == 0) {
            CreateSubscription createSubscription = new CreateSubscription();
            (config.subscriptionId, config.vrfCoordinator) = createSubscription.createSubscription(config.vrfCoordinator,config.account);
        }

        // Fund it

        FundSubscription fundSubscription = new FundSubscription();
        fundSubscription.fundSubscription(config.vrfCoordinator,config.subscriptionId,config.link, config.account);

        vm.startBroadcast(config.account);
        Raffle raffle = new Raffle(
            config.entranceFee,
            config.interval,
            config.vrfCoordinator,
            config.gasLane,
            config.subscriptionId,
            config.callbackGasLimit
        );
        vm.stopBroadcast();

        AddConsumer addConsumer = new AddConsumer();
        // don't need to broadcast becauuse already broadcasting in AddConsumer
        addConsumer.addConsumer(address(raffle), config.vrfCoordinator, config.subscriptionId,config.account);
        return (raffle, helperConfig);
    }
}
