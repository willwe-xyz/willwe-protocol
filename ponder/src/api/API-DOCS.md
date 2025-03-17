## Contents

- [Chat Messages](#chat-messages)
- [Events](#events)
- [Nodes](#nodes)
- [Signatures and Movements](#signatures-and-movements)
- [Search](#search)
- [Statistics](#statistics)

## Chat Messages

The chat messaging system allows users to communicate within the context of a specific node.

### Get Chat Messages

Retrieve chat messages for a specific node.

**Endpoint:**

GET /api/chat/messages

**Query Parameters:**
- `nodeId` (required): The ID of the node to get messages for
- `limit` (optional): Maximum number of messages to return (default: 50)
- `before` (optional): Timestamp to get messages before this time (for pagination)

**Example Request:**
```bash
curl -X GET "/api/chat/messages?nodeId=123456&limit=10"
```

{
  "messages": [
    {
      "id": "9b1deb4d-3b7d-4bad-9bdd-2b0d7b3dcb6d",
      "nodeId": "123456",
      "sender": "0x742d35Cc6634C0532925a3b844Bc454e4438f44e",
      "content": "Hello world!",
      "timestamp": 1652345678000,
      "networkId": "11155420"
    }
  ],
  "meta": {
    "limit": 10,
    "nodeId": "123456"
  }
}

I'll create a comprehensive API documentation file specifically for your Ponder API. Let me place this in your docs directory.

## Step-by-Step Solution:
1. Create an API documentation file focused on the most important endpoints
2. Document the chat message functionality that you added
3. Cover events, node information, and signatures
4. Make it developer-friendly with examples and explanations

### [ponder-api-reference.md](file:///home/pbq1/Desktop/willwe/willwe/docs/ponder-api-reference.md)

```markdown
# WillWe Ponder API Documentation

This document provides comprehensive documentation for the WillWe Ponder API. The API allows developers to interact with indexed blockchain data, including nodes, events, movements, chat messages, and more.

## Base URL

All API requests should be made to:

```
/api
```

## Contents

- [Chat Messages](#chat-messages)
- [Events](#events)
- [Nodes](#nodes)
- [Signatures and Movements](#signatures-and-movements)
- [Search](#search)
- [Statistics](#statistics)

## Chat Messages

The chat messaging system allows users to communicate within the context of a specific node.

### Get Chat Messages

Retrieve chat messages for a specific node.

**Endpoint:**
```
GET /api/chat/messages
```

**Query Parameters:**
- `nodeId` (required): The ID of the node to get messages for
- `limit` (optional): Maximum number of messages to return (default: 50)
- `before` (optional): Timestamp to get messages before this time (for pagination)

**Example Request:**
```bash
curl -X GET "/api/chat/messages?nodeId=123456&limit=10"
```

**Example Response:**
```json
{
  "messages": [
    {
      "id": "9b1deb4d-3b7d-4bad-9bdd-2b0d7b3dcb6d",
      "nodeId": "123456",
      "sender": "0x742d35Cc6634C0532925a3b844Bc454e4438f44e",
      "content": "Hello world!",
      "timestamp": 1652345678000,
      "networkId": "11155420"
    }
  ],
  "meta": {
    "limit": 10,
    "nodeId": "123456"
  }
}
```

### Post Chat Message

Send a new chat message for a specific node.

**Endpoint:**
```
POST /api/chat/messages
```

**Request Body:**
```json
{
  "nodeId": "123456",
  "sender": "0x742d35Cc6634C0532925a3b844Bc454e4438f44e",
  "content": "Hello, this is my message!",
  "networkId": "11155420"
}
```

**Example Request:**
```bash
curl -X POST "/api/chat/messages" \
  -H "Content-Type: application/json" \
  -d '{"nodeId":"123456","sender":"0x742d35Cc6634C0532925a3b844Bc454e4438f44e","content":"Hello, this is my message!","networkId":"11155420"}'
```

**Example Response:**
```json
{
  "success": true,
  "message": {
    "id": "9b1deb4d-3b7d-4bad-9bdd-2b0d7b3dcb6d",
    "nodeId": "123456",
    "sender": "0x742d35Cc6634C0532925a3b844Bc454e4438f44e",
    "content": "Hello, this is my message!",
    "timestamp": 1652345678000,
    "networkId": "11155420"
  }
}
```

**Validation Rules:**
- Messages must be 1000 characters or less
- The node must exist in the system
- `nodeId`, `sender`, and `content` are required fields

### Validate Chat Message

Validate a chat message before sending it.

**Endpoint:**
```
POST /api/chat/validate
```

**Request Body:**
```json
{
  "content": "Message to validate"
}
```

**Example Response:**
```json
{
  "isValid": true,
  "validations": {
    "tooLong": false,
    "isEmpty": false,
    "hasInvalidChars": false
  },
  "content": "Message to validate"
}
```

## Events

Events are records of on-chain activity stored in the database. The API provides several ways to access event data.

### Get Events for a User

Retrieve events associated with a specific user address.

**Endpoint:**
```
GET /api/user/:address
```

**Path Parameters:**
- `address`: The Ethereum address of the user

**Query Parameters:**
- `limit` (optional): Maximum number of events to return (default: 50)
- `includeNodes` (optional): Include node data for nodes the user is a member of (default: false)

**Example Request:**
```bash
curl -X GET "/api/user/0x742d35Cc6634C0532925a3b844Bc454e4438f44e?includeNodes=true"
```

**Example Response:**
```json
{
  "address": "0x742d35cc6634c0532925a3b844bc454e4438f44e",
  "memberships": [
    {
      "id": "tx-0x123...-0",
      "nodeId": "123456",
      "who": "0x742d35cc6634c0532925a3b844bc454e4438f44e",
      "when": "1652345678",
      "isValid": true
    }
  ],
  "events": [
    {
      "id": "tx-0x456...-1",
      "nodeId": "123456",
      "who": "0x742d35cc6634c0532925a3b844bc454e4438f44e",
      "eventName": "ConfigSignal",
      "eventType": "configSignal",
      "when": "1652345700",
      "createdBlockNumber": "12345678",
      "network": "optimismsepolia",
      "networkId": "11155420"
    }
  ],
  "signals": [
    {
      "id": "tx-0x789...-2-membrane",
      "nodeId": "123456",
      "who": "0x742d35cc6634c0532925a3b844bc454e4438f44e",
      "signalType": "membrane",
      "signalValue": "789",
      "currentPrevalence": "1000000000000000000",
      "when": "1652345800",
      "network": "optimismsepolia",
      "networkId": "11155420"
    }
  ],
  "nodes": [
    {
      "nodeId": "123456",
      "inflation": "1000000000000000000",
      // Additional node properties...
    }
  ]
}
```

### Get Filtered Events

Retrieve events with custom filtering options.

**Endpoint:**
```
GET /api/events
```

**Query Parameters:**
- `nodeId` (optional): Filter events for a specific node ID
- `who` (optional): Filter events by address
- `eventType` (optional): Filter by event type (e.g., "mint", "burn", "configSignal")
- `networkId` (optional): Filter by network ID
- `from` (optional): Filter events after this timestamp
- `to` (optional): Filter events before this timestamp
- `limit` (optional): Maximum number of events to return (default: 50)
- `offset` (optional): Pagination offset (default: 0)

**Example Request:**
```bash
curl -X GET "/api/events?nodeId=123456&eventType=configSignal&limit=10"
```

**Example Response:**
```json
{
  "events": [
    {
      "id": "tx-0x123...-0",
      "nodeId": "123456",
      "who": "0x742d35cc6634c0532925a3b844bc454e4438f44e",
      "eventName": "ConfigSignal",
      "eventType": "configSignal",
      "when": "1652345678",
      "createdBlockNumber": "12345678",
      "network": "optimismsepolia",
      "networkId": "11155420"
    }
    // Additional events...
  ],
  "meta": {
    "total": 42,
    "limit": 10,
    "offset": 0,
    "filters": {
      "nodeId": "123456",
      "eventType": "configSignal",
      "networkId": null,
      "fromTimestamp": null,
      "toTimestamp": null
    }
  }
}
```

## Nodes

The API provides access to node data and related information.

### Get Node Information

Get comprehensive information about a node, including events, signals, and relationships.

**Endpoint:**
```
GET /api/node/:nodeId
```

**Path Parameters:**
- `nodeId`: The ID of the node to fetch

**Example Request:**
```bash
curl -X GET "/api/node/123456"
```

**Example Response:**
```json
{
  "node": {
    "nodeId": "123456",
    "inflation": "1000000000000000000",
    // Other node properties...
  },
  "parentNode": {
    "nodeId": "123455",
    // Parent node properties...
  },
  "childNodes": [
    {
      "nodeId": "123457",
      // Child node properties...
    }
  ],
  "memberships": [
    // Membership data...
  ],
  "signals": [
    // Signal data...
  ],
  "events": [
    // Event data...
  ]
}
```

### Get Multiple Nodes

Retrieve multiple nodes with filtering and pagination.

**Endpoint:**
```
GET /api/nodes
```

**Query Parameters:**
- `limit` (optional): Maximum number of nodes to return (default: 20)
- `offset` (optional): Pagination offset (default: 0)
- `networkId` (optional): Filter by network ID
- `createdAfter` (optional): Filter nodes created after this timestamp
- `hasMembraneId` (optional): Filter nodes that have a non-zero membrane ID
- `sortBy` (optional): Field to sort by (options: "createdAt", "updatedAt", "totalSupply")
- `sortOrder` (optional): Sort direction (options: "asc", "desc", default: "desc")

**Example Request:**
```bash
curl -X GET "/api/nodes?limit=5&hasMembraneId=true&sortBy=totalSupply&sortOrder=desc"
```

**Example Response:**
```json
{
  "nodes": [
    {
      "nodeId": "123456",
      "inflation": "1000000000000000000",
      // Other node properties...
    },
    // Additional nodes...
  ],
  "meta": {
    "total": 42,
    "limit": 5,
    "offset": 0,
    "filters": {
      "networkId": null,
      "createdAfter": null,
      "hasMembraneId": true
    }
  }
}
```

## Signatures and Movements

The API provides endpoints for working with signatures and movements.

### Submit a Signature

Submit a signature for a node or movement.

**Endpoint:**
```
POST /api/events/signature
```

**Request Body:**
```json
{
  "nodeId": "123456",
  "who": "0x742d35Cc6634C0532925a3b844Bc454e4438f44e",
  "networkId": "11155420",
  "signature": "0x1234567890abcdef..."
}
```

**Example Request:**
```bash
curl -X POST "/api/events/signature" \
  -H "Content-Type: application/json" \
  -d '{"nodeId":"123456","who":"0x742d35Cc6634C0532925a3b844Bc454e4438f44e","networkId":"11155420","signature":"0x1234567890abcdef..."}'
```

**Example Response:**
```json
{
  "success": true,
  "eventId": "sig-1652345678000-abc123"
}
```

### Get Movements with Signatures

Retrieve movements and their associated signature queues.

**Endpoint:**
```
GET /api/movements
```

**Query Parameters:**
- `nodeId` (optional): Filter movements by node ID
- `initiator` (optional): Filter movements by initiator address
- `category` (optional): Filter by movement category ("Revert", "AgentMajority", "EnergeticMajority")
- `networkId` (optional): Filter by network ID
- `limit` (optional): Maximum number of movements to return (default: 20)
- `offset` (optional): Pagination offset (default: 0)

**Example Request:**
```bash
curl -X GET "/api/movements?nodeId=123456"
```

**Example Response:**
```json
{
  "movements": [
    {
      "id": "mov-0x123...",
      "nodeId": "123456",
      "category": "AgentMajority",
      "initiator": "0x742d35cc6634c0532925a3b844bc454e4438f44e",
      "exeAccount": "0x742d35cc6634c0532925a3b844bc454e4438f44e",
      "viaNode": "0",
      "expiresAt": "1652445678",
      "description": "Proposal to change membrane",
      "executedPayload": "",
      "createdBlockNumber": "12345678",
      "network": "optimismsepolia",
      "networkId": "11155420",
      "signatureQueues": [
        {
          "id": "queue-0x456...",
          "state": "Initialized",
          "movementId": "mov-0x123...",
          "signers": [
            "0x742d35cc6634c0532925a3b844bc454e4438f44e"
          ],
          "signatures": [
            "0x9876543210abcdef..."
          ],
          "createdBlockNumber": "12345678",
          "network": "optimismsepolia",
          "networkId": "11155420",
          "signatures": [
            {
              "id": "sig-0x789...",
              "nodeId": "123456",
              "signer": "0x742d35cc6634c0532925a3b844bc454e4438f44e",
              "signature": "0x9876543210abcdef...",
              "signatureQueueHash": "queue-0x456...",
              "submitted": true,
              "when": "1652345700",
              "network": "optimismsepolia",
              "networkId": "11155420"
            }
          ]
        }
      ]
    }
  ],
  "meta": {
    "total": 1,
    "limit": 20,
    "offset": 0,
    "filters": {
      "nodeId": "123456",
      "initiator": null,
      "category": null,
      "networkId": null
    }
  }
}
```

## Search

The API provides a versatile search function to find nodes, users, and membranes.

**Endpoint:**
```
GET /api/search
```

**Query Parameters:**
- `q` (required): Search query (min 2 characters)
- `type` (optional): Type of results to include (options: "nodes", "users", "membranes", "all", default: "all")
- `limit` (optional): Maximum number of results per type (default: 20)

**Example Request:**
```bash
curl -X GET "/api/search?q=example&type=all&limit=5"
```

**Example Response:**
```json
{
  "nodes": [
    // Node results...
  ],
  "users": [
    // User results...
  ],
  "membranes": [
    // Membrane results...
  ],
  "query": "example",
  "type": "all"
}
```

## Statistics

The API provides statistical information about the platform.

**Endpoint:**
```
GET /api/stats
```

**Query Parameters:**
- `networkId` (optional): Filter statistics by network ID

**Example Request:**
```bash
curl -X GET "/api/stats?networkId=11155420"
```

**Example Response:**
```json
{
  "stats": {
    "nodesCount": 42,
    "eventsCount": 1024,
    "uniqueUsersCount": 256,
    "membranesCount": 15
  },
  "networkId": "11155420"
}
```

## Error Handling

The API returns appropriate HTTP status codes:

- `200 OK`: Request successful
- `400 Bad Request`: Invalid parameters or request body
- `404 Not Found`: Resource not found
- `500 Internal Server Error`: Server error

Error responses have this format:

```json
{
  "error": "Error message describing what went wrong"
}
```

## Pagination

Most list endpoints support pagination with these parameters:

- `limit`: Maximum number of items to return (default varies by endpoint)
- `offset`: Number of items to skip (default: 0)

The response includes metadata about pagination:

```json
{
  "data": [...],
  "meta": {
    "total": 100,  // Total number of items available
    "limit": 20,   // Requested limit
    "offset": 0    // Requested offset
  }
}
```

## Development Integration

When integrating with these API endpoints in your frontend application, consider:

1. Using caching for frequently accessed data
2. Implementing optimistic UI updates for better user experience
3. Handling rate limiting appropriately
4. Processing data on the client side to minimize API requests

This documentation covers the key endpoints implemented in `/ponder/src/api/index.ts`, focusing on chat messages, events, nodes, and signatures.
```

This documentation provides a comprehensive guide focused specifically on the Ponder API implementation, with special attention to chat messages, events, node information, and signatures as requested.

Made changes.

{
  "nodeId": "123456",
  "sender": "0x742d35Cc6634C0532925a3b844Bc454e4438f44e",
  "content": "Hello, this is my message!",
  "networkId": "11155420"
}

curl -X POST "/api/chat/messages" \
  -H "Content-Type: application/json" \
  -d '{"nodeId":"123456","sender":"0x742d35Cc6634C0532925a3b844Bc454e4438f44e","content":"Hello, this is my message!","networkId":"11155420"}'

  {
  "success": true,
  "message": {
    "id": "9b1deb4d-3b7d-4bad-9bdd-2b0d7b3dcb6d",
    "nodeId": "123456",
    "sender": "0x742d35Cc6634C0532925a3b844Bc454e4438f44e",
    "content": "Hello, this is my message!",
    "timestamp": 1652345678000,
    "networkId": "11155420"
  }
}

{
  "success": true,
  "message": {
    "id": "9b1deb4d-3b7d-4bad-9bdd-2b0d7b3dcb6d",
    "nodeId": "123456",
    "sender": "0x742d35Cc6634C0532925a3b844Bc454e4438f44e",
    "content": "Hello, this is my message!",
    "timestamp": 1652345678000,
    "networkId": "11155420"
  }
}

I'll create a comprehensive API documentation file specifically for your Ponder API. Let me place this in your docs directory.

## Step-by-Step Solution:
1. Create an API documentation file focused on the most important endpoints
2. Document the chat message functionality that you added
3. Cover events, node information, and signatures
4. Make it developer-friendly with examples and explanations

### [ponder-api-reference.md](file:///home/pbq1/Desktop/willwe/willwe/docs/ponder-api-reference.md)

```markdown
# WillWe Ponder API Documentation

This document provides comprehensive documentation for the WillWe Ponder API. The API allows developers to interact with indexed blockchain data, including nodes, events, movements, chat messages, and more.

## Base URL

All API requests should be made to:

```
/api
```

## Contents

- [Chat Messages](#chat-messages)
- [Events](#events)
- [Nodes](#nodes)
- [Signatures and Movements](#signatures-and-movements)
- [Search](#search)
- [Statistics](#statistics)

## Chat Messages

The chat messaging system allows users to communicate within the context of a specific node.

### Get Chat Messages

Retrieve chat messages for a specific node.

**Endpoint:**
```
GET /api/chat/messages
```

**Query Parameters:**
- `nodeId` (required): The ID of the node to get messages for
- `limit` (optional): Maximum number of messages to return (default: 50)
- `before` (optional): Timestamp to get messages before this time (for pagination)

**Example Request:**
```bash
curl -X GET "/api/chat/messages?nodeId=123456&limit=10"
```

**Example Response:**
```json
{
  "messages": [
    {
      "id": "9b1deb4d-3b7d-4bad-9bdd-2b0d7b3dcb6d",
      "nodeId": "123456",
      "sender": "0x742d35Cc6634C0532925a3b844Bc454e4438f44e",
      "content": "Hello world!",
      "timestamp": 1652345678000,
      "networkId": "11155420"
    }
  ],
  "meta": {
    "limit": 10,
    "nodeId": "123456"
  }
}
```

### Post Chat Message

Send a new chat message for a specific node.

**Endpoint:**
```
POST /api/chat/messages
```

**Request Body:**
```json
{
  "nodeId": "123456",
  "sender": "0x742d35Cc6634C0532925a3b844Bc454e4438f44e",
  "content": "Hello, this is my message!",
  "networkId": "11155420"
}
```

**Example Request:**
```bash
curl -X POST "/api/chat/messages" \
  -H "Content-Type: application/json" \
  -d '{"nodeId":"123456","sender":"0x742d35Cc6634C0532925a3b844Bc454e4438f44e","content":"Hello, this is my message!","networkId":"11155420"}'
```

**Example Response:**
```json
{
  "success": true,
  "message": {
    "id": "9b1deb4d-3b7d-4bad-9bdd-2b0d7b3dcb6d",
    "nodeId": "123456",
    "sender": "0x742d35Cc6634C0532925a3b844Bc454e4438f44e",
    "content": "Hello, this is my message!",
    "timestamp": 1652345678000,
    "networkId": "11155420"
  }
}
```

**Validation Rules:**
- Messages must be 1000 characters or less
- The node must exist in the system
- `nodeId`, `sender`, and `content` are required fields

### Validate Chat Message

Validate a chat message before sending it.

**Endpoint:**
```
POST /api/chat/validate
```

**Request Body:**
```json
{
  "content": "Message to validate"
}
```

**Example Response:**
```json
{
  "isValid": true,
  "validations": {
    "tooLong": false,
    "isEmpty": false,
    "hasInvalidChars": false
  },
  "content": "Message to validate"
}
```

## Events

Events are records of on-chain activity stored in the database. The API provides several ways to access event data.

### Get Events for a User

Retrieve events associated with a specific user address.

**Endpoint:**
```
GET /api/user/:address
```

**Path Parameters:**
- `address`: The Ethereum address of the user

**Query Parameters:**
- `limit` (optional): Maximum number of events to return (default: 50)
- `includeNodes` (optional): Include node data for nodes the user is a member of (default: false)

**Example Request:**
```bash
curl -X GET "/api/user/0x742d35Cc6634C0532925a3b844Bc454e4438f44e?includeNodes=true"
```

**Example Response:**
```json
{
  "address": "0x742d35cc6634c0532925a3b844bc454e4438f44e",
  "memberships": [
    {
      "id": "tx-0x123...-0",
      "nodeId": "123456",
      "who": "0x742d35cc6634c0532925a3b844bc454e4438f44e",
      "when": "1652345678",
      "isValid": true
    }
  ],
  "events": [
    {
      "id": "tx-0x456...-1",
      "nodeId": "123456",
      "who": "0x742d35cc6634c0532925a3b844bc454e4438f44e",
      "eventName": "ConfigSignal",
      "eventType": "configSignal",
      "when": "1652345700",
      "createdBlockNumber": "12345678",
      "network": "optimismsepolia",
      "networkId": "11155420"
    }
  ],
  "signals": [
    {
      "id": "tx-0x789...-2-membrane",
      "nodeId": "123456",
      "who": "0x742d35cc6634c0532925a3b844bc454e4438f44e",
      "signalType": "membrane",
      "signalValue": "789",
      "currentPrevalence": "1000000000000000000",
      "when": "1652345800",
      "network": "optimismsepolia",
      "networkId": "11155420"
    }
  ],
  "nodes": [
    {
      "nodeId": "123456",
      "inflation": "1000000000000000000",
      // Additional node properties...
    }
  ]
}
```

### Get Filtered Events

Retrieve events with custom filtering options.

**Endpoint:**
```
GET /api/events
```

**Query Parameters:**
- `nodeId` (optional): Filter events for a specific node ID
- `who` (optional): Filter events by address
- `eventType` (optional): Filter by event type (e.g., "mint", "burn", "configSignal")
- `networkId` (optional): Filter by network ID
- `from` (optional): Filter events after this timestamp
- `to` (optional): Filter events before this timestamp
- `limit` (optional): Maximum number of events to return (default: 50)
- `offset` (optional): Pagination offset (default: 0)

**Example Request:**
```bash
curl -X GET "/api/events?nodeId=123456&eventType=configSignal&limit=10"
```

**Example Response:**
```json
{
  "events": [
    {
      "id": "tx-0x123...-0",
      "nodeId": "123456",
      "who": "0x742d35cc6634c0532925a3b844bc454e4438f44e",
      "eventName": "ConfigSignal",
      "eventType": "configSignal",
      "when": "1652345678",
      "createdBlockNumber": "12345678",
      "network": "optimismsepolia",
      "networkId": "11155420"
    }
    // Additional events...
  ],
  "meta": {
    "total": 42,
    "limit": 10,
    "offset": 0,
    "filters": {
      "nodeId": "123456",
      "eventType": "configSignal",
      "networkId": null,
      "fromTimestamp": null,
      "toTimestamp": null
    }
  }
}
```

## Nodes

The API provides access to node data and related information.

### Get Node Information

Get comprehensive information about a node, including events, signals, and relationships.

**Endpoint:**
```
GET /api/node/:nodeId
```

**Path Parameters:**
- `nodeId`: The ID of the node to fetch

**Example Request:**
```bash
curl -X GET "/api/node/123456"
```

**Example Response:**
```json
{
  "node": {
    "nodeId": "123456",
    "inflation": "1000000000000000000",
    // Other node properties...
  },
  "parentNode": {
    "nodeId": "123455",
    // Parent node properties...
  },
  "childNodes": [
    {
      "nodeId": "123457",
      // Child node properties...
    }
  ],
  "memberships": [
    // Membership data...
  ],
  "signals": [
    // Signal data...
  ],
  "events": [
    // Event data...
  ]
}
```

### Get Multiple Nodes

Retrieve multiple nodes with filtering and pagination.

**Endpoint:**
```
GET /api/nodes
```

**Query Parameters:**
- `limit` (optional): Maximum number of nodes to return (default: 20)
- `offset` (optional): Pagination offset (default: 0)
- `networkId` (optional): Filter by network ID
- `createdAfter` (optional): Filter nodes created after this timestamp
- `hasMembraneId` (optional): Filter nodes that have a non-zero membrane ID
- `sortBy` (optional): Field to sort by (options: "createdAt", "updatedAt", "totalSupply")
- `sortOrder` (optional): Sort direction (options: "asc", "desc", default: "desc")

**Example Request:**
```bash
curl -X GET "/api/nodes?limit=5&hasMembraneId=true&sortBy=totalSupply&sortOrder=desc"
```

**Example Response:**
```json
{
  "nodes": [
    {
      "nodeId": "123456",
      "inflation": "1000000000000000000",
      // Other node properties...
    },
    // Additional nodes...
  ],
  "meta": {
    "total": 42,
    "limit": 5,
    "offset": 0,
    "filters": {
      "networkId": null,
      "createdAfter": null,
      "hasMembraneId": true
    }
  }
}
```

## Signatures and Movements

The API provides endpoints for working with signatures and movements.

### Submit a Signature

Submit a signature for a node or movement.

**Endpoint:**
```
POST /api/events/signature
```

**Request Body:**
```json
{
  "nodeId": "123456",
  "who": "0x742d35Cc6634C0532925a3b844Bc454e4438f44e",
  "networkId": "11155420",
  "signature": "0x1234567890abcdef..."
}
```

**Example Request:**
```bash
curl -X POST "/api/events/signature" \
  -H "Content-Type: application/json" \
  -d '{"nodeId":"123456","who":"0x742d35Cc6634C0532925a3b844Bc454e4438f44e","networkId":"11155420","signature":"0x1234567890abcdef..."}'
```

**Example Response:**
```json
{
  "success": true,
  "eventId": "sig-1652345678000-abc123"
}
```

### Get Movements with Signatures

Retrieve movements and their associated signature queues.

**Endpoint:**
```
GET /api/movements
```

**Query Parameters:**
- `nodeId` (optional): Filter movements by node ID
- `initiator` (optional): Filter movements by initiator address
- `category` (optional): Filter by movement category ("Revert", "AgentMajority", "EnergeticMajority")
- `networkId` (optional): Filter by network ID
- `limit` (optional): Maximum number of movements to return (default: 20)
- `offset` (optional): Pagination offset (default: 0)

**Example Request:**
```bash
curl -X GET "/api/movements?nodeId=123456"
```

**Example Response:**
```json
{
  "movements": [
    {
      "id": "mov-0x123...",
      "nodeId": "123456",
      "category": "AgentMajority",
      "initiator": "0x742d35cc6634c0532925a3b844bc454e4438f44e",
      "exeAccount": "0x742d35cc6634c0532925a3b844bc454e4438f44e",
      "viaNode": "0",
      "expiresAt": "1652445678",
      "description": "Proposal to change membrane",
      "executedPayload": "",
      "createdBlockNumber": "12345678",
      "network": "optimismsepolia",
      "networkId": "11155420",
      "signatureQueues": [
        {
          "id": "queue-0x456...",
          "state": "Initialized",
          "movementId": "mov-0x123...",
          "signers": [
            "0x742d35cc6634c0532925a3b844bc454e4438f44e"
          ],
          "signatures": [
            "0x9876543210abcdef..."
          ],
          "createdBlockNumber": "12345678",
          "network": "optimismsepolia",
          "networkId": "11155420",
          "signatures": [
            {
              "id": "sig-0x789...",
              "nodeId": "123456",
              "signer": "0x742d35cc6634c0532925a3b844bc454e4438f44e",
              "signature": "0x9876543210abcdef...",
              "signatureQueueHash": "queue-0x456...",
              "submitted": true,
              "when": "1652345700",
              "network": "optimismsepolia",
              "networkId": "11155420"
            }
          ]
        }
      ]
    }
  ],
  "meta": {
    "total": 1,
    "limit": 20,
    "offset": 0,
    "filters": {
      "nodeId": "123456",
      "initiator": null,
      "category": null,
      "networkId": null
    }
  }
}
```

## Search

The API provides a versatile search function to find nodes, users, and membranes.

**Endpoint:**
```
GET /api/search
```

**Query Parameters:**
- `q` (required): Search query (min 2 characters)
- `type` (optional): Type of results to include (options: "nodes", "users", "membranes", "all", default: "all")
- `limit` (optional): Maximum number of results per type (default: 20)

**Example Request:**
```bash
curl -X GET "/api/search?q=example&type=all&limit=5"
```

**Example Response:**
```json
{
  "nodes": [
    // Node results...
  ],
  "users": [
    // User results...
  ],
  "membranes": [
    // Membrane results...
  ],
  "query": "example",
  "type": "all"
}
```

## Statistics

The API provides statistical information about the platform.

**Endpoint:**
```
GET /api/stats
```

**Query Parameters:**
- `networkId` (optional): Filter statistics by network ID

**Example Request:**
```bash
curl -X GET "/api/stats?networkId=11155420"
```

**Example Response:**
```json
{
  "stats": {
    "nodesCount": 42,
    "eventsCount": 1024,
    "uniqueUsersCount": 256,
    "membranesCount": 15
  },
  "networkId": "11155420"
}
```

## Error Handling

The API returns appropriate HTTP status codes:

- `200 OK`: Request successful
- `400 Bad Request`: Invalid parameters or request body
- `404 Not Found`: Resource not found
- `500 Internal Server Error`: Server error

Error responses have this format:

```json
{
  "error": "Error message describing what went wrong"
}
```

## Pagination

Most list endpoints support pagination with these parameters:

- `limit`: Maximum number of items to return (default varies by endpoint)
- `offset`: Number of items to skip (default: 0)

The response includes metadata about pagination:

```json
{
  "data": [...],
  "meta": {
    "total": 100,  // Total number of items available
    "limit": 20,   // Requested limit
    "offset": 0    // Requested offset
  }
}
```

## Development Integration

When integrating with these API endpoints in your frontend application, consider:

1. Using caching for frequently accessed data
2. Implementing optimistic UI updates for better user experience
3. Handling rate limiting appropriately
4. Processing data on the client side to minimize API requests
