// This file exports event handlers for Membrane contract events
import { ponder } from "ponder:registry";
import { membranes, events } from "../ponder.schema";

export const handleMembraneCreated = async ({ event, context }) => {
  const { db } = context;
  console.log("Membrane Created:", event.args);

  try {
    // Create a unique ID for the membrane
    const membraneId = `${event.args.membraneId.toString()}-${event.block.hash}`;
    
    // Insert the membrane
    await db.insert(membranes).values({ 
      id: membraneId,
      membraneId: event.args.membraneId,
      creator: event.args.creator,
      metadataCID: event.args.CID,
      data: "", // Empty string as default
      tokens: [], // Empty array as default
      balances: [], // Empty array as default
      createdAt: event.block.timestamp, // Use block timestamp
      createdBlockNumber: event.block.number,
      network: context.network.name.toLowerCase()
    }).onConflictDoNothing();

    console.log("Inserted Membrane:", membraneId);
    
    // Create a unique ID for the event with fallback for undefined transaction hash
    const transactionHash = event.transaction?.hash || `tx-${event.block.hash}-${event.block.number}`;
    const eventId = `${transactionHash}-${event.log.logIndex}`;
    
    // Insert the event
    await db.insert(events).values({
      id: eventId,
      nodeId: "0", // Default nodeId since membranes aren't directly tied to nodes
      who: event.args.creator,
      eventName: "MembraneCreated",
      eventType: "membraneSignal",
      when: event.block.timestamp,
      createdBlockNumber: event.block.number,
      network: context.network.name.toLowerCase()
    }).onConflictDoNothing();

    console.log("Inserted MembraneCreated event:", eventId);
  } catch (error) {
    console.error("Error in handleMembraneCreated:", error);
  }
};