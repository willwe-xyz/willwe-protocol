/**
 * Main index file for Ponder event handlers
 * Maps contract events to their respective handler functions
 * Updated for Ponder v0.9.27 API
 */

import { ponder } from "ponder:registry";
import * as schema from "./schema";

// Helper function to add network prefix to IDs
function createNetworkId(id: string): string {
  return `optimismsepolia-${id}`;
}

// Import the handlers from respective files
import * as WillWeHandlers from './WillWe';
import * as ExecutionHandlers from './Execution';

// Register WillWe contract event handlers
ponder.on("WillWe:NewRootNode", WillWeHandlers.handleNewRootNode);
ponder.on("WillWe:NewNode", WillWeHandlers.handleNewNode);
ponder.on("WillWe:MembershipMinted", WillWeHandlers.handleMembershipMinted);
ponder.on("WillWe:Transfer", WillWeHandlers.handleTransfer);
ponder.on("WillWe:UserNodeSignal", WillWeHandlers.handleUserNodeSignal); // Updated from NewSignal to UserNodeSignal
ponder.on("WillWe:ConfigChange", WillWeHandlers.handleConfigChange);
ponder.on("WillWe:NewEndpoint", WillWeHandlers.handleNewEndpoint);
ponder.on("WillWe:NewControl", WillWeHandlers.handleNewControl);

// Register Execution contract event handlers
ponder.on("Execution:NewMovement", ExecutionHandlers.handleNewMovement);
ponder.on("Execution:MovementStatusChange", ExecutionHandlers.handleMovementStatusChange);
ponder.on("Execution:NewExecutionQueue", ExecutionHandlers.handleNewExecutionQueue);
ponder.on("Execution:QueueStatusChange", ExecutionHandlers.handleQueueStatusChange);
ponder.on("Execution:NewSignature", ExecutionHandlers.handleNewSignature);
// All handlers are now imported from their respective files
// No duplicate implementations needed here
  const { nodeId, to, tokenId } = event.args;
  
  await context.db.insert("Membership").values({
    id: createNetworkId(`membership-${tokenId}`),
    nodeId,
    tokenId,
    owner: to,
    createdAt: BigInt(event.block.timestamp),
    createdBlockNumber: BigInt(event.block.number),
    network: "optimismsepolia",
  });

// ponder.on("WillWe:Transfer", async ({ event, context }) => {
//   const { from, to, tokenId } = event.args;
  
//   // Skip token minting (from zero address)
//   if (from === '0x0000000000000000000000000000000000000000') {
//     return;
//   }
  
//   // Record the transfer event
//   await context.db.insert("TokenEvent").values({
//     id: createNetworkId(`transfer-${event.log.transactionHash}-${event.log.logIndex}`),
//     tokenId,
//     from,
//     to,
//     eventType: "transfer",
//     createdAt: BigInt(event.block.timestamp),
//     createdBlockNumber: BigInt(event.block.number),
//     network: "optimismsepolia",
//   });
  
//   // Update the membership owner
//   const membership = await context.db.find("Membership", { tokenId });
  
//   if (membership) {
//     await context.db.update("Membership", { id: membership.id })
//       .set({ owner: to });
//   }
// });

ponder.on("WillWe:NewSignal", async ({ event, context }) => {
  const { signalId, nodeId, creator, signalType, data } = event.args;
  
  await context.db.insert("Signal").values({
    id: createNetworkId(`signal-${signalId}`),
    signalId: BigInt(signalId),
    nodeId: BigInt(nodeId),
    creator,
    signalType,
    data,
    createdAt: BigInt(event.block.timestamp),
    createdBlockNumber: BigInt(event.block.number),
    transactionHash: event.log.transactionHash,
    network: "optimismsepolia",
  });
});

ponder.on("WillWe:ConfigChange", async ({ event, context }) => {
  const { nodeId, key, value } = event.args;
  
  await context.db.insert("ConfigChange").values({
    id: createNetworkId(`config-${nodeId}-${key}-${event.log.transactionHash}`),
    nodeId: BigInt(nodeId),
    configType: key, // Schema uses configType, not key
    creator: event.log.address, // Using contract address as creator
    data: value, // Schema uses data, not value
    createdAt: BigInt(event.block.timestamp),
    createdBlockNumber: BigInt(event.block.number),
    transactionHash: event.log.transactionHash,
    network: "optimismsepolia",
  });
});

ponder.on("WillWe:NewEndpoint", async ({ event, context }) => {
  const { nodeId, endpointId, endpointType, data } = event.args;
  
  await context.db.insert("Endpoint").values({
    id: createNetworkId(`endpoint-${endpointId}`),
    nodeId: BigInt(nodeId),
    endpointId: BigInt(endpointId),
    creator: event.log.address, // Using contract address as creator
    endpointType,
    data,
    createdAt: BigInt(event.block.timestamp),
    createdBlockNumber: BigInt(event.block.number),
    network: "optimismsepolia",
  });
});

ponder.on("WillWe:NewControl", async ({ event, context }) => {
  const { nodeId, controlId, controlType, data } = event.args;
  
  await context.db.insert("Control").values({
    id: createNetworkId(`control-${controlId}`),
    nodeId: BigInt(nodeId),
    controlId: BigInt(controlId),
    creator: event.transaction?.from ?? "0x0000000000000000000000000000000000000000",
    controlType,
    data,
    createdAt: BigInt(event.block.timestamp),
    createdBlockNumber: BigInt(event.block.number),
    network: "optimismsepolia",
  });
});

// Execution contract event handlers
ponder.on("Execution:NewMovement", async ({ event, context }) => {
  const { movementId, nodeId, creator, destination, amount } = event.args;
  
  await context.db.insert("Movement").values({
    id: createNetworkId(`movement-${movementId}`),
    movementId,
    nodeId,
    creator,
    destination,
    amount,
    status: "created",
    createdAt: BigInt(event.block.timestamp),
    createdBlockNumber: BigInt(event.block.number),
    network: "optimismsepolia",
  });
});

ponder.on("Execution:MovementStatusChange", async ({ event, context }) => {
  const { movementId, status } = event.args;
  
  const movement = await context.db.find("Movement", { movementId });
  
  if (movement) {
    await context.db.update("Movement", { id: movement.id })
      .set({ status });
  }
});

ponder.on("Execution:NewExecutionQueue", async ({ event, context }) => {
  const { queueId, nodeId, movementId } = event.args;
  
  await context.db.insert("ExecutionQueue").values({
    id: createNetworkId(`queue-${queueId}`),
    queueId,
    nodeId,
    movementId,
    status: "pending",
    createdAt: BigInt(event.block.timestamp),
    createdBlockNumber: BigInt(event.block.number),
    network: "optimismsepolia",
  });
});

ponder.on("Execution:QueueStatusChange", async ({ event, context }) => {
  const { queueId, status } = event.args;
  
  const queue = await context.db.find("ExecutionQueue", { queueId });
  
  if (queue) {
    await context.db.update("ExecutionQueue", { id: queue.id })
      .set({ status });
  }
});

ponder.on("Execution:NewSignature", async ({ event, context }) => {
  const { queueId, signer, signature } = event.args;
  
  await context.db.insert("Signature").values({
    id: createNetworkId(`signature-${queueId}-${signer}`),
    queueId,
    signer,
    signature,
    createdAt: BigInt(event.block.timestamp),
    createdBlockNumber: BigInt(event.block.number),
    network: "optimismsepolia",
  });
});
