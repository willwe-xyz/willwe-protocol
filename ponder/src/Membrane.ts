// This file exports event handlers for Membrane contract events
import { ponder } from "ponder:registry";
import { membranes, events, nodeSignals } from "../ponder.schema";

// Helper function to create a unique event ID
const createEventId = (event) => {
  const transactionHash = event.transaction?.hash || `tx-${event.block.hash}-${event.block.number}`;
  return `${transactionHash}-${event.log.logIndex}`;
};

// Helper function to safely insert an event
const saveEvent = async ({ db, event, nodeId, who, eventName, eventType, network }) => {
  try {
    if (!db || !event || !event.block) {
      console.error(`Missing required parameters for saveEvent: db=${!!db}, event=${!!event}, block=${!!(event && event.block)}`);
      return false;
    }

    const eventId = createEventId(event);
    
    // Get network info with proper fallbacks - ensure we have valid values
    const networkName = (network?.name || event.context?.network?.name || "optimismsepolia").toLowerCase();
    const networkId = (network?.id || event.context?.network?.id || "11155420").toString();
    
    // Ensure nodeId is a string
    const safeNodeId = (nodeId || "0").toString();
    // Ensure who is a string
    const safeWho = (who || event.transaction?.from || "unknown").toString();
    
    await db.insert(events).values({
      id: eventId,
      nodeId: safeNodeId,
      who: safeWho,
      eventName: eventName || "Unknown",
      eventType: eventType || "configSignal",
      when: event.block.timestamp,
      createdBlockNumber: event.block.number,
      networkId: networkId,
      network: networkName
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
    const network = context.network || { name: "optimismsepolia", id: "11155420" };
    const networkId = network.id.toString();
    const networkName = network.name.toLowerCase();
    
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
      network: networkName,
      networkId: networkId
    }).onConflictDoNothing();

    console.log("Inserted Membrane:", membraneId);
    
    // Save the event using the helper function
    await saveEvent({
      db,
      event,
      nodeId: "0", // Default nodeId since membranes aren't directly tied to nodes initially
      who: event.args.creator,
      eventName: "MembraneCreated",
      eventType: "membraneSignal",
      network: network
    });
    
    // Save a record in nodeSignals for tracking membrane creation
    await db.insert(nodeSignals).values({
      id: `${createEventId(event)}-membrane-creation`,
      nodeId: "0", // No specific node at creation time
      who: event.args.creator,
      signalType: "membrane",
      signalValue: event.args.membraneId.toString(),
      currentPrevalence: "0", // Not applicable for creation
      when: event.block.timestamp,
      network: networkName,
      networkId: networkId
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
    const network = context.network || { name: "optimismsepolia", id: "11155420" };
    await saveEvent({
      db,
      event,
      nodeId: "0", // Default nodeId
      who: event.args.willWeAddress || event.transaction.from,
      eventName: "WillWeSet",
      eventType: "configSignal",
      network: network
    });
    
    console.log(`Recorded WillWeSet event for address ${event.args.willWeAddress || event.transaction.from}`);
  } catch (error) {
    console.error("Error in handleWillWeSet:", error);
  }
};