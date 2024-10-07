// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./GigMarketplace.sol";

contract ChatSystem {
    GigMarketplace public gigMarketplace;

    struct Message {
        address sender;
        string content;
        uint256 timestamp;
    }

    struct Conversation {
        uint256 gigId;
        address participant1;
        address participant2;
        uint256 messageCount;
        mapping(uint256 => Message) messages;
    }

    mapping(bytes32 => Conversation) private conversations;

    event MessageSent(bytes32 indexed conversationKey, address indexed sender, uint256 timestamp);
    event ConversationInitialized(bytes32 indexed conversationKey, address indexed participant1, address indexed participant2, uint256 gigId);

    constructor(address _gigMarketplaceAddress) {
        gigMarketplace = GigMarketplace(_gigMarketplaceAddress);
    }

    modifier onlyParticipants(bytes32 _conversationKey) {
        Conversation storage conversation = conversations[_conversationKey];
        require(msg.sender == conversation.participant1 || msg.sender == conversation.participant2, "Only conversation participants can access this conversation");
        _;
    }

    function initializeConversation(address _participant2, uint256 _gigId) public returns (bytes32) {
        require(_participant2 != address(0) && _participant2 != msg.sender, "Invalid participant address");
        
        (address client, , , , , , , address hiredArtisan, , , ) = gigMarketplace.getGigDetails(_gigId);
        require(msg.sender == client || msg.sender == hiredArtisan, "Only gig participants can initialize a gig conversation");
        require(_participant2 == client || _participant2 == hiredArtisan, "Participant must be part of the gig");

        bytes32 conversationKey = keccak256(abi.encodePacked(_gigId, client, hiredArtisan));
        require(conversations[conversationKey].participant1 == address(0), "Conversation already initialized");

        Conversation storage chat = conversations[conversationKey];
        chat.gigId = _gigId;
        chat.participant1 = client;
        chat.participant2 = hiredArtisan;
        chat.messageCount = 0;

        emit ConversationInitialized(conversationKey, chat.participant1, chat.participant2, _gigId);
        return conversationKey;
    }

    function sendMessage(uint256 _gigId, string memory _content) external returns (bytes32) {
        (address client, , , , , , , address hiredArtisan, , , ) = gigMarketplace.getGigDetails(_gigId);
        require(msg.sender == client || msg.sender == hiredArtisan, "Only gig participants can send messages");

        bytes32 conversationKey = keccak256(abi.encodePacked(_gigId, client, hiredArtisan));
        Conversation storage conversation = conversations[conversationKey];

        if (conversation.participant1 == address(0)) {
            conversationKey = initializeConversation(msg.sender == client ? hiredArtisan : client, _gigId);
            conversation = conversations[conversationKey];
        }

        uint256 messageIndex = conversation.messageCount;
        conversation.messages[messageIndex] = Message({
            sender: msg.sender,
            content: _content,
            timestamp: block.timestamp
        });

        conversation.messageCount++;
        emit MessageSent(conversationKey, msg.sender, block.timestamp);
        return conversationKey;
    }

    function getGigConversation(uint256 _gigId) external view returns (bytes32 conversationKey, Message[] memory messages) {
        (address client, , , , , , , address hiredArtisan, , , ) = gigMarketplace.getGigDetails(_gigId);
        require(msg.sender == client || msg.sender == hiredArtisan, "Only gig participants can access the conversation");

        conversationKey = keccak256(abi.encodePacked(_gigId, client, hiredArtisan));
        Conversation storage conversation = conversations[conversationKey];

        require(conversation.participant1 != address(0), "Conversation does not exist");

        messages = new Message[](conversation.messageCount);
        for (uint256 i = 0; i < conversation.messageCount; i++) {
            messages[i] = conversation.messages[i];
        }

        return (conversationKey, messages);
    }

    function getConversationDetails(bytes32 _conversationKey) external view returns (uint256 gigId, address participant1, address participant2, uint256 messageCount) {
        Conversation storage conversation = conversations[_conversationKey];
        return (conversation.gigId, conversation.participant1, conversation.participant2, conversation.messageCount);
    }
}