// This file contains event handlers for WillWe contract events
import { ponder } from "ponder:registry";
import { db } from "ponder:api";
import { nodes } from "ponder:schema";

export function handleNewRootNode({ event, context }) {
  console.log("New Root Node created:", event.args);

  const row = context.db.insert(nodes).values({
    nodeId: event.args.nodeId,
    owner: event.args.owner,
    startBlock: event.block.number,
    endBlock: event.args.endBlock,
    createdAt: new Date()
  });

  console.log("Inserted Node:", row);
}

export function handleNewNode({ event, context }) {
  console.log("New Node created:", event.args);
  const row = context.db.insert(nodes).values({
    nodeId: event.args.nodeId,
    owner: event.args.owner,
    startBlock: event.block.number,
    endBlock: event.args.endBlock,
    createdAt: new Date()
  });
}

export function handleMembershipMinted({ event, context }) {
  console.log("Membership Minted:", event.args);
}

export function handleTransferSingle({ event, context }) {
  console.log("Transfer Single:", event.args);
}

export function handleTransferBatch({ event, context }) {
  console.log("Transfer Batch:", event.args);
}

export function handleUserNodeSignal({ event, context }) {
  console.log("User Node Signal:", event.args);
}

export function handleConfigSignal({ event, context }) {
  console.log("Config Signal:", event.args);
}

export function handleCreatedEndpoint({ event, context }) {
  console.log("Created Endpoint:", event.args);
}
