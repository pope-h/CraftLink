// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./Registry.sol";
import "./PaymentProcessor.sol";

contract GigMarketplace {
    Registry public registry;
    PaymentProcessor public paymentProcessor;

    struct Gig {
        address client;
        string title;
        string description;
        string[] requiredSkills;
        uint256 budget;
        uint256 duration;
        uint256 startTime;
        uint256 endTime;
        address[] applicants;
        address hiredArtisan;
        uint256 paymentId;
        bool artisanCompleteGig;
        bool isCompleted;
        bool isClosed;
    }

    mapping(uint256 => Gig) public gigs;
    uint256 public gigCounter;

    event GigCreated(uint256 indexed gigId, address indexed client, string title, uint256 duration);
    event GigApplicationSubmitted(uint256 indexed gigId, address indexed artisan);
    event ArtisanHired(uint256 indexed gigId, address indexed artisan, uint256 startTime, uint256 endTime);
    event GigDurationExtended(uint256 indexed gigId, uint256 newEndTime);
    event GigCompleted(uint256 indexed gigId);
    event GigClosed(uint256 indexed gigId);

    constructor(address _registryAddress, address _paymentProcessorAddress) {
        registry = Registry(_registryAddress);
        paymentProcessor = PaymentProcessor(_paymentProcessorAddress);
        gigCounter = 0;
    }

    function createGig(
        string memory _title,
        string memory _description,
        string[] memory _requiredSkills,
        uint256 _budget,
        uint256 _duration
    ) external {
        require(registry.isClient(msg.sender), "Only Clients can create gigs");

        paymentProcessor.createPayment(msg.sender, _budget);
        uint256 paymentId = paymentProcessor.currentPaymentId();

        uint256 newGigId = gigCounter++;
        gigs[newGigId] = Gig({
            client: msg.sender,
            title: _title,
            description: _description,
            requiredSkills: _requiredSkills,
            budget: _budget,
            duration: _duration,
            startTime: 0,
            endTime: 0,
            applicants: new address[](0),
            hiredArtisan: address(0),
            paymentId: paymentId,
            artisanCompleteGig: false,
            isCompleted: false,
            isClosed: false
        });

        emit GigCreated(newGigId, msg.sender, _title, _duration);
    }

    function applyForGig(uint256 _gigId) external {
        require(_gigId < gigCounter, "Invalid gig ID");
        require(registry.isArtisanVerified(msg.sender), "Only verified artisans can apply");
        require(!gigs[_gigId].isClosed, "Gig has been closed");
        require(gigs[_gigId].hiredArtisan == address(0), "Artisan already hired for this gig");

        gigs[_gigId].applicants.push(msg.sender);
        emit GigApplicationSubmitted(_gigId, msg.sender);
    }

    function hireArtisan(uint256 _gigId, address _artisan) external {
        require(_gigId < gigCounter, "Invalid gig ID");
        require(msg.sender == gigs[_gigId].client, "Only the client can hire an artisan");
        require(gigs[_gigId].hiredArtisan == address(0), "An artisan has already been hired");
        require(!gigs[_gigId].isClosed, "Gig has been closed");

        bool isApplicant = false;
        for (uint256 i = 0; i < gigs[_gigId].applicants.length; i++) {
            if (gigs[_gigId].applicants[i] == _artisan) {
                isApplicant = true;
                break;
            }
        }
        require(isApplicant, "The selected artisan has not applied for this gig");

        gigs[_gigId].hiredArtisan = _artisan;
        gigs[_gigId].startTime = block.timestamp;
        gigs[_gigId].endTime = block.timestamp + gigs[_gigId].duration;

        emit ArtisanHired(_gigId, _artisan, gigs[_gigId].startTime, gigs[_gigId].endTime);
    }

    function extendGigDuration(uint256 _gigId, uint256 _additionalTime) external {
        require(_gigId < gigCounter, "Invalid gig ID");
        require(msg.sender == gigs[_gigId].client, "Only the client can extend the gig duration");
        require(!gigs[_gigId].isCompleted, "Cannot extend completed gigs");
        require(!gigs[_gigId].isClosed, "Cannot extend closed gigs");
        require(gigs[_gigId].hiredArtisan != address(0), "Cannot extend gigs without hired artisans");
        require(block.timestamp <= gigs[_gigId].endTime, "Cannot extend expired gigs");

        gigs[_gigId].endTime += _additionalTime;
        gigs[_gigId].duration += _additionalTime;

        emit GigDurationExtended(_gigId, gigs[_gigId].endTime);
    }

    function completeGig(uint256 _gigId) external {
        require(_gigId < gigCounter, "Invalid gig ID");
        require(msg.sender == gigs[_gigId].hiredArtisan, "Only hired Artisan can mark the gig as completed");
        require(!gigs[_gigId].isCompleted, "Gig is already marked as completed");
        require(!gigs[_gigId].isClosed, "Gig has been closed");
        require(block.timestamp <= gigs[_gigId].endTime, "Gig duration has expired");

        gigs[_gigId].artisanCompleteGig = true;
        emit GigCompleted(_gigId);
    }

    function confirmCompleteGig(uint256 _gigId) external {
        require(_gigId < gigCounter, "Invalid gig ID");
        require(msg.sender == gigs[_gigId].client, "Only gig owner can confirm completion");
        require(gigs[_gigId].artisanCompleteGig, "This gig has not been completed yet");
        require(!gigs[_gigId].isCompleted, "Gig is already marked as completed");
        require(!gigs[_gigId].isClosed, "Gig has been closed");

        gigs[_gigId].isCompleted = true;
        paymentProcessor.releaseArtisanFunds(gigs[_gigId].hiredArtisan, gigs[_gigId].paymentId);
        emit GigCompleted(_gigId);
    }

    function closeGig(uint256 _gigId) external {
        require(_gigId < gigCounter, "Invalid gig ID");
        require(msg.sender == gigs[_gigId].client, "Only gig owner can close the gig");
        require(
            gigs[_gigId].hiredArtisan == address(0) || block.timestamp > gigs[_gigId].endTime,
            "Cannot close an active gig before its end time"
        );
        require(!gigs[_gigId].isCompleted, "Completed gigs cannot be closed");
        require(!gigs[_gigId].isClosed, "Gig is already closed");

        gigs[_gigId].isClosed = true;
        if (gigs[_gigId].hiredArtisan == address(0)) {
            paymentProcessor.refundClientFunds(gigs[_gigId].paymentId);
        }
        emit GigClosed(_gigId);
    }

    function getGigDetails(uint256 _gigId)
        external
        view
        returns (
            address client,
            string memory title,
            string memory description,
            uint256 budget,
            uint256 duration,
            uint256 startTime,
            address[] memory applicants,
            address hiredArtisan,
            uint256 paymentId,
            bool isCompleted,
            bool isClosed
        )
    {
        require(_gigId < gigCounter, "Invalid gig ID");
        Gig storage gig = gigs[_gigId];
        return (
            gig.client,
            gig.title,
            gig.description,
            gig.budget,
            gig.duration,
            gig.startTime,
            gig.applicants,
            gig.hiredArtisan,
            gig.paymentId,
            gig.isCompleted,
            gig.isClosed
        );
    }
}
