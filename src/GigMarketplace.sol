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
        uint256 paymentId;
        address hiredArtisan;
        string location;
        uint256 startTime;
        uint256 endTime;
    }

    mapping(uint256 => Gig) public gigs;
    mapping(uint256 => address[]) public gigApplicants;
    mapping(uint256 => bool) public artisanCompleteGig;
    mapping(uint256 => bool) public isGigCompleted;
    mapping(uint256 => bool) public isGigClosed;
    uint256 public gigCounter;

    event GigCreated(uint256 indexed gigId, address indexed client, string title, uint256 duration, string location);
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
        uint256 _duration,
        string memory _location
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
            paymentId: paymentId,
            hiredArtisan: address(0),
            location: _location,
            startTime: 0,
            endTime: 0
        });

        emit GigCreated(newGigId, msg.sender, _title, _duration, _location);
    }

    function applyForGig(uint256 _gigId) external {
        require(_gigId < gigCounter, "Invalid gig ID");
        require(registry.isArtisanVerified(msg.sender), "Only verified artisans can apply");
        require(!isGigClosed[_gigId], "Gig has been closed");
        require(gigs[_gigId].hiredArtisan == address(0), "Artisan already hired for this gig");

        gigApplicants[_gigId].push(msg.sender);
        emit GigApplicationSubmitted(_gigId, msg.sender);
    }

    function hireArtisan(uint256 _gigId, address _artisan) external {
        Gig storage gig = gigs[_gigId];
        require(_gigId < gigCounter, "Invalid gig ID");
        require(msg.sender == gig.client, "Only the client can hire an artisan");
        require(gig.hiredArtisan == address(0), "An artisan has already been hired");
        require(!isGigClosed[_gigId], "Gig has been closed");
        require(_isApplicant(_gigId, _artisan), "The selected artisan has not applied for this gig");

        gig.hiredArtisan = _artisan;
        gig.startTime = block.timestamp;
        gig.endTime = block.timestamp + gig.duration;

        emit ArtisanHired(_gigId, _artisan, gig.startTime, gig.endTime);
    }

    function extendGigDuration(uint256 _gigId, uint256 _additionalTime) external {
        Gig storage gig = gigs[_gigId];
        require(_gigId < gigCounter, "Invalid gig ID");
        require(msg.sender == gig.client, "Only the client can extend the gig duration");
        require(!isGigCompleted[_gigId] && !isGigClosed[_gigId], "Cannot extend completed or closed gigs");
        require(gig.hiredArtisan != address(0), "Cannot extend gigs without hired artisans");
        require(block.timestamp <= gig.endTime, "Cannot extend expired gigs");

        gig.endTime += _additionalTime;
        gig.duration += _additionalTime;

        emit GigDurationExtended(_gigId, gig.endTime);
    }

    function completeGig(uint256 _gigId) external {
        Gig storage gig = gigs[_gigId];
        require(_gigId < gigCounter, "Invalid gig ID");
        require(msg.sender == gig.hiredArtisan, "Only hired Artisan can mark the gig as completed");
        require(!isGigCompleted[_gigId] && !isGigClosed[_gigId], "Gig is already completed or closed");
        require(block.timestamp <= gig.endTime, "Gig duration has expired");

        artisanCompleteGig[_gigId] = true;
        emit GigCompleted(_gigId);
    }

    function confirmCompleteGig(uint256 _gigId) external {
        Gig storage gig = gigs[_gigId];
        require(_gigId < gigCounter, "Invalid gig ID");
        require(msg.sender == gig.client, "Only gig owner can confirm completion");
        require(
            artisanCompleteGig[_gigId] && !isGigCompleted[_gigId] && !isGigClosed[_gigId],
            "Gig cannot be confirmed as completed"
        );

        isGigCompleted[_gigId] = true;
        paymentProcessor.releaseArtisanFunds(gig.hiredArtisan, gig.paymentId);
        emit GigCompleted(_gigId);
    }

    function closeGig(uint256 _gigId) external {
        Gig storage gig = gigs[_gigId];
        require(_gigId < gigCounter, "Invalid gig ID");
        require(msg.sender == gig.client, "Only gig owner can close the gig");
        require(
            gig.hiredArtisan == address(0) || block.timestamp > gig.endTime,
            "Cannot close an active gig before its end time"
        );
        require(!isGigCompleted[_gigId] && !isGigClosed[_gigId], "Gig is already completed or closed");

        isGigClosed[_gigId] = true;
        if (gig.hiredArtisan == address(0)) {
            paymentProcessor.refundClientFunds(gig.paymentId);
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
            uint256 endTime,
            address hiredArtisan,
            uint256 paymentId,
            bool isCompleted,
            bool isClosed
        )
    {
        require(_gigId < gigCounter, "Invalid gig ID");
        Gig storage gig = gigs[_gigId];
        isCompleted = isGigCompleted[_gigId];
        isClosed = isGigClosed[_gigId];
        return (
            gig.client,
            gig.title,
            gig.description,
            gig.budget,
            gig.duration,
            gig.startTime,
            gig.endTime,
            gig.hiredArtisan,
            gig.paymentId,
            isCompleted,
            isClosed
        );
    }

    function getGigTimeline(uint256 _gigId) external view returns (uint256, uint256) {
        require(_gigId < gigCounter, "Invalid gig ID");
        return (gigs[_gigId].startTime, gigs[_gigId].endTime);
    }

    function getGigApplicants(uint256 _gigId) external view returns (address[] memory) {
        require(_gigId < gigCounter, "Invalid gig ID");
        return gigApplicants[_gigId];
    }

    function getGigRequiredSkills(uint256 _gigId) external view returns (string[] memory) {
        require(_gigId < gigCounter, "Invalid gig ID");
        return gigs[_gigId].requiredSkills;
    }

    function _isApplicant(uint256 _gigId, address _artisan) internal view returns (bool) {
        address[] memory applicants = gigApplicants[_gigId];
        for (uint256 i = 0; i < applicants.length; i++) {
            if (applicants[i] == _artisan) {
                return true;
            }
        }
        return false;
    }
}
