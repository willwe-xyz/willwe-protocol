// This file exports event handlers for Membrane contract events
import { ponder } from "ponder:registry";
import { membranes, events, nodeSignals } from "../ponder.schema";

// Helper function to create a unique event ID
const createEventId = (event) => {
  const transactionHash = event.transaction?.hash || `tx-${event.block.hash}-${event.block.number}`;
  return `${transactionHash}-${event.log.logIndex}`;
};

// Helper function to safely insert an event
const saveEvent = async ({ db, event, nodeId, who, eventName, eventType }) => {
  try {
    const eventId = createEventId(event);
    const network = event.context ? event.context.network?.name?.toLowerCase() : "optimismsepolia";
    
    await db.insert(events).values({
      id: eventId,
      nodeId: nodeId.toString(),
      who: who,
      eventName: eventName,
      eventType: eventType,
      when: event.block.timestamp,
      createdBlockNumber: event.block.number,
      network: network
    }).onConflictDoNothing();
    
    console.log(`Inserted ${eventName} event:`, eventId);
    return true;
  } catch (error) {
    console.error(`Error saving ${eventName} event:`, error);
    return false;
  }
};

export const handleMembraneCreated = async ({ event, context }) => {
  const { db } = context;
  console.log("Membrane Created:", event.args);

  try {
    // Create a unique ID for the membrane
    const membraneId = `${event.args.membraneId.toString()}-${event.block.hash}`;
    const network = context.network?.name?.toLowerCase() || "optimismsepolia";
    
    // Insert the membrane
    await db.insert(membranes).values({ 
      id: membraneId,
      membraneId: event.args.membraneId,
      creator: event.args.creator,
      metadataCID: event.args.CID,
      data: event.args.data || "",
      tokens: [], // Empty array as default
      balances: [], // Empty array as default
      createdAt: event.block.timestamp, // Use block timestamp
      createdBlockNumber: event.block.number,
      network: network
    }).onConflictDoNothing();

    console.log("Inserted Membrane:", membraneId);
    
    // Save the event using the helper function
    await saveEvent({
      db,
      event,
      nodeId: "0", // Default nodeId since membranes aren't directly tied to nodes initially
      who: event.args.creator,
      eventName: "MembraneCreated",
      eventType: "membraneSignal"
    });
    
    // Save a record in nodeSignals for tracking membrane creation
    // This will be useful when displaying a history of membrane activities
    await db.insert(nodeSignals).values({
      id: `${createEventId(event)}-membrane-creation`,
      nodeId: "0", // No specific node at creation time
      who: event.args.creator,
      signalType: "membrane",
      signalValue: event.args.membraneId.toString(),
      currentPrevalence: "0", // Not applicable for creation
      when: event.block.timestamp,
      network: network
    }).onConflictDoNothing();
    
    console.log(`Saved membrane creation signal from ${event.args.creator}`);
  } catch (error) {
    console.error("Error in handleMembraneCreated:", error);
  }
};

export const handleWillWeSet = async ({ event, context }) => {
  const { db } = context;
  console.log("WillWe Set:", event.args);
  
  try {
    // Save the event using the helper function
    await saveEvent({
      db,
      event,
      nodeId: "0", // Default nodeId
      who: event.args.willWeAddress || event.transaction.from,
      eventName: "WillWeSet",
      eventType: "configSignal"
    });
    
    console.log(`Recorded WillWeSet event for address ${event.args.willWeAddress || event.transaction.from}`);
  } catch (error) {
    console.error("Error in handleWillWeSet:", error);
  }
};