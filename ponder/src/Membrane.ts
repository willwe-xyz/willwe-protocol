// This file exports event handlers for Membrane contract events
import { ponder } from "ponder:registry";
import { membranes, events, nodeSignals } from "../ponder.schema";
import { createEventId, saveEvent, safeBigIntStringify } from "./common";

export const handleMembraneCreated = async ({ event, context }) => {
  const { db } = context;
  console.log("Membrane Created:", safeBigIntStringify(event.args));

  try {
    // Safely check if needed properties exist
    if (!event?.args?.membraneId) {
      console.error("Missing membraneId in MembraneCreated event");
      return;
    }
    
    // Create a unique ID for the membrane - safely convert membraneId to string
    const membraneIdString = event.args.membraneId.toString();
    const membraneId = `${membraneIdString}-${event.block.hash}`;
    
    // Safely handle network information with defaults
    const network = context.network || { name: "optimismsepolia", id: "11155420" };
    const networkId = network.chainId?.toString() || "11155420";
    const networkName = (network.name || "optimismsepolia").toLowerCase();
    
    // Insert the membrane
    await db.insert(membranes).values({ 
      id: membraneId,
      membraneId: membraneIdString,
      creator: event.args.creator || event.transaction?.from || "unknown",
      metadataCID: event.args.CID || "",
      data: event.args.data || "",
      tokens: [], // Empty array as default
      balances: [], // Empty array as default
      createdAt: event.block.timestamp, // Use block timestamp
      createdBlockNumber: event.block.number,
      network: networkName,
      networkId: networkId
    }).onConflictDoNothing();

    console.log("Inserted Membrane:", membraneId);
    
    // Save the event using the helper function with more descriptive name
    await saveEvent({
      db,
      event,
      nodeId: "0", // Default nodeId since membranes aren't directly tied to nodes initially
      who: event.args.creator || event.transaction?.from || "unknown",
      eventName: `@${(event.args.creator || event.transaction?.from || "unknown").slice(0, 6)}... created membrane ${membraneIdString}`,
      eventType: "membraneSignal",
      network: network
    });
    
    // Save a record in nodeSignals for tracking membrane creation
    await db.insert(nodeSignals).values({
      id: `${createEventId(event)}-membrane-creation`,
      nodeId: "0", // No specific node at creation time
      who: event.args.creator || event.transaction?.from || "unknown",
      signalType: "membrane",
      signalValue: membraneIdString,
      currentPrevalence: "0", // Not applicable for creation
      when: event.block.timestamp,
      network: networkName,
      networkId: networkId
    }).onConflictDoNothing();
    
    console.log(`Saved membrane creation signal from ${event.args.creator || "unknown"}`);
  } catch (error) {
    console.error("Error in handleMembraneCreated:", error);
    console.error("Event args:", safeBigIntStringify(event?.args || {}));
  }
};

export const handleWillWeSet = async ({ event, context }) => {
  const { db } = context;
  console.log("WillWe Set:", event.args);
  
  try {
    // Save the event using the helper function with more descriptive name
    const network = context.network || { name: "optimismsepolia", id: "11155420" };
    const willWeAddress = event.args.willWeAddress || event.transaction.from;
    await saveEvent({
      db,
      event,
      nodeId: "0", // Default nodeId
      who: willWeAddress,
      eventName: `WillWe contract address set to ${willWeAddress.slice(0, 6)}...`,
      eventType: "configSignal",
      network: network
    });
    
    console.log(`Recorded WillWeSet event for address ${willWeAddress}`);
  } catch (error) {
    console.error("Error in handleWillWeSet:", error);
  }
};