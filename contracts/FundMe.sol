// SPDX-License-Identifier: MIT

pragma solidity ^0.6.6;

import "@chainlink/contracts/src/v0.6/interfaces/AggregatorV3Interface.sol";
import "@chainlink/contracts/src/v0.6/vendor/SafeMathChainlink.sol";

// brownie doesn't understand NPM packages; but, it does understand GitHub packages

contract FundMe {
    using SafeMathChainlink for uint256;

    mapping(address => uint256) public addressToAmountFunded;
    address[] public funders;
    address public owner;
    AggregatorV3Interface public priceFeed;

    constructor(address _priceFeed) public {
        priceFeed = AggregatorV3Interface(_priceFeed);
        owner = msg.sender;
    }

    function fund() public payable {
        // $50
        uint256 minimumUSD = 50 * 10**18;

        // 1 Gwei < $50

        // if(msg.value < minimumUSD){
        // revert?
        // }
        require(
            getConversionRate(msg.value) >= minimumUSD,
            "You need to spend more ETH!"
        );

        addressToAmountFunded[msg.sender] += msg.value;

        // what the ETH -> USD conversion rate

        funders.push(msg.sender);
    }

    function getVersion() public view returns (uint256) {
        // AggregatorV3Interface priceFeed = AggregatorV3Interface(
        //     0x8A753747A1Fa494EC906cE90E9f37563A8AF630e
        // );

        return priceFeed.version();
    }

    function getPrice() public view returns (uint256) {
        // AggregatorV3Interface priceFeed = AggregatorV3Interface(
        //     0x8A753747A1Fa494EC906cE90E9f37563A8AF630e
        // );

        // (
        // uint80 roundId,
        // int256 answer,
        // uint256 startedAt,
        // uint256 updatedAt,
        // uint80 answeredInRound
        // ) = priceFeed.latestRoundData();
        (, int256 answer, , , ) = priceFeed.latestRoundData();

        return uint256(answer * 10000000000); // saves more gas if I don't convert to Wei; optional to do conversion
        // 4,112.77323990
    }

    // 1000000000 Wei = 1 Gwei
    function getConversionRate(uint256 ethAmount)
        public
        view
        returns (uint256)
    {
        uint256 ethPrice = getPrice();
        uint256 ethAmountInUsd = (ethPrice * ethAmount) / 1000000000000000000;

        return ethAmountInUsd;
    }

    modifier onlyOwner() {
        // _;
        require(msg.sender == owner);
        _;
    }

    function withdraw() public payable onlyOwner {
        // only want the contract admin/owner
        // require(msg.sender == owner);

        msg.sender.transfer(address(this).balance);

        for (
            uint256 funderIndex = 0;
            funderIndex < funders.length;
            funderIndex++
        ) {
            address funder = funders[funderIndex];

            addressToAmountFunded[funder] = 0;
        }

        funders = new address[](0);
    }

    function getEntranceFee() public view returns (uint256) {
        uint256 minimumUSD = 50 * 10**18;
        uint256 price = getPrice();
        uint256 precision = 1 * 10**18;

        return (minimumUSD * precision) / price;
    }
}
