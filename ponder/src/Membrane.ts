// This file exports event handlers for Membrane contract events
// Each function is registered in index.ts with the appropriate chainId-based contract name

import { ponder } from "ponder:registry";
import { membranes } from "ponder:schema";
import { db } from "ponder:api";


export const handleMembraneCreated = async ({ event, context }) => {
  console.log("Membrane Created:", event.args);

  const row = await context.db.insert(membranes).values({ 
    id: `${event.args.membraneId.toString()}-${event.block.hash}`,
    membraneId: event.args.membraneId,
    creator: event.args.creator,
    metadataCID: event.args.CID,
    data: "", // Empty string as default
    tokens: [], // Empty array as default
    balances: [], // Empty array as default
    createdAt: event.block.timestamp, // Use block timestamp instead of Date object
    createdBlockNumber: event.block.number,
    network: context.network
  });

  console.log("Inserted Membrane:", row);

};