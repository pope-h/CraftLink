// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./CraftLinkToken.sol";

contract PaymentProcessor {
    CraftLinkToken public token;
    uint256 public platformFeePercentage;
    address public platformWallet; // deployer for now

    struct Payment {
        address client;
        uint256 amount;
        uint256 platformFee;
        bool isReleased;
    }

    mapping(uint256 => Payment) public payments;
    uint256 public nextPaymentId;

    event PaymentCreated(uint256 indexed paymentId, address indexed client, uint256 amount);
    event PaymentReleased(uint256 indexed paymentId, uint256 amountToArtisan, uint256 platformFee);
    event PaymentRefunded(uint256 indexed paymentId, uint256 amountToClient);
    event PlatformFeeUpdated(uint256 newFeePercentage);

    constructor(address _tokenAddress) {
        token = CraftLinkToken(_tokenAddress);
        platformFeePercentage = 5; // 5%
        platformWallet = msg.sender;
    }

    function createPayment(address _client, uint256 _amount) external {
        require(_amount > 20, "Payment amount must be greater than 20");
        require(token.balanceOf(_client) >= _amount, "Insufficient token balance");

        uint256 platformFee = (_amount * platformFeePercentage) / 100;

        token.transferFrom(_client, address(this), _amount);
        nextPaymentId++;

        payments[nextPaymentId] =
            Payment({client: _client, amount: _amount, platformFee: platformFee, isReleased: false});

        emit PaymentCreated(nextPaymentId, _client, _amount);
    }

    function currentPaymentId() external view returns (uint256) {
        return nextPaymentId;
    }

    function releaseArtisanFunds(address _artisan, uint256 _paymentId) external {
        Payment storage payment = payments[_paymentId];
        require(!payment.isReleased, "Payment has already been released");

        payment.isReleased = true;
        uint256 amountToArtisan = payment.amount - payment.platformFee;

        token.transfer(_artisan, amountToArtisan);
        token.transfer(platformWallet, payment.platformFee);

        emit PaymentReleased(_paymentId, amountToArtisan, payment.platformFee);
    }

    function refundClientFunds(uint256 _paymentId) external {
        Payment storage payment = payments[_paymentId];
        require(!payment.isReleased, "Payment has already been released");

        payment.isReleased = true;
        token.transfer(payment.client, payment.amount);

        emit PaymentRefunded(_paymentId, payment.amount);
    }

    function updatePlatformFee(uint256 _newFeePercentage) external {
        require(msg.sender == platformWallet, "Only the platform wallet can update the fee");
        require(_newFeePercentage <= 20, "Fee percentage must be between 0 and 20");

        platformFeePercentage = _newFeePercentage;
        emit PlatformFeeUpdated(_newFeePercentage);
    }

    function getPaymentDetails(uint256 _paymentId)
        external
        view
        returns (address client, uint256 amount, uint256 platformFee, bool isReleased)
    {
        Payment storage payment = payments[_paymentId];
        return (payment.client, payment.amount, payment.platformFee, payment.isReleased);
    }
}
