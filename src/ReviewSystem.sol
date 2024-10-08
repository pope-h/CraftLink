// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./Registry.sol";
import "./GigMarketplace.sol";

contract ReviewSystem {
    Registry public registry;
    GigMarketplace public gigMarketplace;

    struct Review {
        address reviewer;
        address reviewee;
        uint256 gigId;
        uint256 rating;
        string comment;
        uint256 timestamp;
    }

    mapping(address => Review[]) public artisanReviews;

    event ReviewSubmitted(address indexed reviewer, address indexed reviewee, uint256 indexed gigId, uint256 rating);

    constructor(address _registryAddress, address _gigMarketplaceAddress) {
        registry = Registry(_registryAddress);
        gigMarketplace = GigMarketplace(_gigMarketplaceAddress);
    }

    function submitReview(uint256 _gigId, uint256 _rating, string memory _comment) external {
        require(_rating >= 1 && _rating <= 5, "Rating must be between 1 and 5");

        (address client,,,,,,, address hiredArtisan,, bool isCompleted, bool isClosed) =
            gigMarketplace.getGigDetails(_gigId);

        require(msg.sender == client, "Only the client can submit a review");
        require(isCompleted, "Gig must be completed before submitting a review");
        require(!isClosed, "Cannot review a closed gig");

        Review memory newReview = Review({
            reviewer: msg.sender,
            reviewee: hiredArtisan,
            gigId: _gigId,
            rating: _rating,
            comment: _comment,
            timestamp: block.timestamp
        });

        artisanReviews[hiredArtisan].push(newReview);
        emit ReviewSubmitted(msg.sender, hiredArtisan, _gigId, _rating);
    }

    function getArtisanReviews(address _artisan) external view returns (Review[] memory) {
        return artisanReviews[_artisan];
    }

    function getArtisanAverageRating(address _artisan) external view returns (uint256) {
        Review[] memory reviews = artisanReviews[_artisan];
        if (reviews.length == 0) {
            return 0;
        }

        uint256 totalRating = 0;
        for (uint256 i = 0; i < reviews.length; i++) {
            totalRating += reviews[i].rating;
        }

        return totalRating / reviews.length;
    }
}
