# CraftLink Platform Workflow

## 1. User Registration and Verification

### Artisan Registration
1. Artisan calls `registerAsArtisan()` in the `Registry` contract, having provided:
   - Name
   - Contact information
   - Location
   - Skills
   - Years of experience
   - Certifications
and any more or less data. The frontend would send this information to IPFS or anyother decentralized storage.
2. The ipfsHash is then sent to the contract.

3. The system emits an `ArtisanRegistered` event.

### Artisan Verification
1. Make a button for an authorized verifier (to be implemented) calls `verifyArtisan()` in the `Registry` contract.
2. The system updates the artisan's status to verified and emits an `ArtisanVerified` event.

### Client Registration
1. Client calls `registerAsClient()` in the `Registry` contract, having provided the necessary data.
2. The frontend would send this information to IPFS or anyother decentralized storage.
3. The ipfsHash is then sent to the contract.
4. The system emits an `ClientRegistered` event.

## 2. Token Distribution

1. Users (both artisans and clients. This would be corrected to only Clients in later implementations) can claim tokens by calling the `claim()` function in the `CraftLinkToken` contract.
2. Each address can claim 1000 CLT tokens once.

## 3. Gig Creation and Management

### Creating a Gig
1. Client calls `createGig()` in the `GigMarketplace` contract, providing:
   - Title
   - Description
   - Required skills
   - Budget
   - Deadline

2. The budget will be sent from the client's wallet to the `PaymentProcessor` contract.
3. The system creates a new gig and emits a `GigCreated` event.

### Applying for a Gig
1. Verified artisans call `applyForGig()` in the `GigMarketplace` contract.
2. The system adds the artisan to the list of applicants and emits a `GigApplicationSubmitted` event.

### Hiring an Artisan
1. Client calls `hireArtisan()` in the `GigMarketplace` contract, selecting an artisan from the applicants.
2. The system updates the gig with the hired artisan and emits an `ArtisanHired` event.

### Completing a Gig
1. Artisan calls `completeGig()` in the `GigMarketplace` contract when the work is completed by him.
2. Client calls `confirmCompleteGig()` in the `GigMarketplace` contract to confirm the work is satisfactory.
3. The system marks the gig as completed and emits a `GigCompleted` event.
4. _Future implementation will involve implementing a `Dispute Resolution System`

### Closing a Gig
1. Client can call `closeGig()` in the `GigMarketplace` contract to close an uncompleted gig.
2. The system marks the gig as closed and emits a `GigClosed` event.

## 4. Communication

### Initializing a Conversation
1. Either the client or artisan calls `initializeConversation()` in the `ChatSystem` contract.
2. For gig-related conversations, provide the `gigId` (This is automatically filled when the gig is clicked).
3. The system creates a new conversation and emits a `ConversationInitialized` event.

### Sending Messages
1. Participants call `sendMessage()` in the `ChatSystem` contract to send messages.
2. The system stores the message and emits a `MessageSent` event.

### Retrieving Messages
- The frontend calls the `getConversationMessage()`, `getMessageCount()`, or `getLatestMessage()` to retrieve conversation details once the `MessageSent` event is sent.

## 5. Reviews

### Submitting a Review
1. After completing a gig, the client calls `submitReview()` in the `ReviewSystem` contract, providing:
   - Gig ID
   - Rating (1-5)
   - Comment

2. The system stores the review and emits a `ReviewSubmitted` event.

### Retrieving Reviews
- Users can call `getArtisanReviews()` or `getArtisanAverageRating()` to view an artisan's reviews and ratings.

## Frontend Considerations

1. User Dashboard:
   - Display user's CLT token balance
   - Show active gigs, applications, and conversations

2. Gig Marketplace:
   - List available gigs
   - Allow filtering by skills, budget, and deadline

3. Artisan Profiles:
   - Display artisan details, skills, and reviews

4. Messaging System:
   - Implement a real-time chat interface using events from the `ChatSystem` contract

5. Payment Integration:
   - Show payment status for gigs
   - Implement UX for creating payments and releasing funds

6. Review System:
   - Allow clients to submit reviews after gig completion
   - Display reviews and average ratings on artisan profiles

### NOTE this is just a suggestion and not a mandation. The Frontend is free to implement the flow how it suits best.

## DEPLOYMENT
- Registry deployed at: 0x5a3C6288A295E0CE7ef6cD73fAE56e1DaD934938
https://sepolia.basescan.org/address/0x5a3c6288a295e0ce7ef6cd73fae56e1dad934938

- CraftLinkToken deployed at: 0xCaeC3B55dF16ec145B9e262a3Bd2A225b081630F
https://sepolia.basescan.org/address/0xCaeC3B55dF16ec145B9e262a3Bd2A225b081630F

- PaymentProcessor deployed at: 0x07be041AB8641e624944a1c0A4c00A8Cd8aEb7D4
https://sepolia.basescan.org/address/0x07be041AB8641e624944a1c0A4c00A8Cd8aEb7D4

- GigMarketplace deployed at: 0x0dFC9bCA80DA4B46DD3e8c26120975A94F97be3b
https://sepolia.basescan.org/address/0x0dFC9bCA80DA4B46DD3e8c26120975A94F97be3b

- ReviewSystem deployed at: 0xa2BC0C9A4cAf2Aa2AFB87836881Ec308CE43E711
https://sepolia.basescan.org/address/0xa2BC0C9A4cAf2Aa2AFB87836881Ec308CE43E711

- ChatSystem deployed at: 0x0654eDAbC62bE2043aF22d72F4f617c6978C9BAb
https://sepolia.basescan.org/address/0x0654eDAbC62bE2043aF22d72F4f617c6978C9BAb

removed `forge-std/=lib/forge-std/src/` from the remappings.txt to avoid error.