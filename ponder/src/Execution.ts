// This file exports event handlers for Execution contract events
import { ponder } from "ponder:registry";
import { events, movements, signatureQueues, signatures, nodeSignals } from "../ponder.schema";
import { createEventId, saveEvent, getDefaultNetwork, safeBigIntStringify, safeString } from "./common";

// Helper function to safely convert any value to string
const safeToString = (value, defaultValue = "0") => {
  if (value === undefined || value === null) return defaultValue;
  try {
    return value.toString();
  } catch (error) {
    console.error(`Error converting value to string:`, error);
    return defaultValue;
  }
};

export const handleNewMovementCreated = async ({ event, context }) => {
  const { db } = context;
  console.log("New Movement Created:", safeBigIntStringify(event.args));
  if (! context.network) throw new Error("Missing network context");

  try {
    // Safely check if required args exist
    if (!event?.args) {
      console.error("Missing args in NewMovementCreated event");
      return;
    }

    // Safely extract nodeId with detailed logging
    let nodeId = "0"; // Safe default
    try {
      console.log(`Movement nodeId type: ${typeof event.args.nodeId}, value: ${event.args.nodeId}`);
      nodeId = event.args.nodeId ? safeToString(event.args.nodeId) : "0";
      console.log(`Using nodeId: ${nodeId}`);
    } catch (error) {
      console.error(`Error extracting nodeId: ${error.message}`);
    }
    
    // Create a unique ID for the movement - safely handle movementHash
    let movementId;
    try {
      // Check if the properties exist before attempting to access them
      if (event.args.movementHash) {
        movementId = safeToString(event.args.movementHash);
      } else if (event.args.movementId) {
        movementId = safeToString(event.args.movementId);
      } else {
        movementId = `mov-${createEventId(event)}`;
      }
    } catch (error) {
      console.error(`Error extracting movementId: ${error.message}`);
      movementId = `mov-${createEventId(event)}`;
    }

    
    // Network info with fallbacks
    const network = context.network;
    const networkId = network.chainId;
    const networkName = network.name;
    
    // Safely get initiator
    const initiator = event.args.initiator || event.transaction?.from || "unknown";
    
    // Safely handle viaNode with extra checking
    let viaNode = "0";
    try {
      if (event.args.viaNode !== undefined) {
        viaNode = safeToString(event.args.viaNode);
      }
    } catch (error) {
      console.error(`Error processing viaNode: ${error.message}`);
    }
    
    // Safely handle expiresAt with extra checking
    let expiresAt;
    try {
      if (event.args.expiresAt !== undefined) {
        expiresAt = safeToString(event.args.expiresAt);
      } else {
        // Default: current time + 1 week
        expiresAt = (BigInt(event.block.timestamp) + BigInt(7 * 24 * 60 * 60)).toString();
      }
    } catch (error) {
      console.error(`Error processing expiresAt: ${error.message}`);
      expiresAt = (BigInt(event.block.timestamp) + BigInt(7 * 24 * 60 * 60)).toString();
    }
    
    // Safe category handling
    let category = "EnergeticMajority"; // default
    try {
      if (event.args.category === 0) {
        category = "Revert";
      } else if (event.args.category === 1) {
        category = "AgentMajority";
      }
    } catch (error) {
      console.error(`Error processing category: ${error.message}`);
    }
    
    // Insert the movement with safe property access and explicit try/catch
    try {
      await db.insert(movements).values({
        id: movementId,
        nodeId: nodeId,
        category: category,
        initiator: initiator,
        exeAccount: event.args.exeAccount || initiator,
        viaNode: viaNode,
        expiresAt: expiresAt,
        description: event.args.description || "",
        executedPayload: event.args.executedPayload || "",
        createdBlockNumber: event.block.number,
        network: networkName,
        networkId: networkId
      }).onConflictDoNothing();

      console.log("Inserted Movement:", movementId);
    } catch (insertError) {
      console.error(`Error inserting movement record: ${insertError.message}`);
    }
    
    // Use the helper function to save the event
    try {
      // Create custom event record without using saveEvent to avoid additional errors
      await db.insert(events).values({
        id: createEventId(event),
        nodeId: nodeId,
        who: initiator,
        eventName: "New Movement Created",
        eventType: "newmovement",
        when: event.block.timestamp,
        createdBlockNumber: event.block.number,
        networkId: networkId,
        network: networkName
      }).onConflictDoNothing();
      
      console.log(`Saved NewMovementCreated event for node ${nodeId}`);
    } catch (eventError) {
      console.error(`Error saving event: ${eventError.message}`);
    }
    
    // Also record as a node signal for historical tracking
    try {
      await db.insert(nodeSignals).values({
        id: `${createEventId(event)}-movement-created`,
        nodeId: nodeId,
        who: initiator,
        signalType: "redistribution", // Closest signal type for governance actions
        signalValue: movementId,
        currentPrevalence: "0", // Not applicable for movements
        when: event.block.timestamp,
        network: networkName,
        networkId: networkId
      }).onConflictDoNothing();
      
      console.log(`Saved movement creation signal from ${initiator}`);
    } catch (signalError) {
      console.error(`Error saving node signal: ${signalError.message}`);
    }
  } catch (error) {
    console.error("Error in handleNewMovementCreated:", error);
    console.error("Event args:", safeBigIntStringify(event?.args || {}));
  }
};

export const handleQueueExecuted = async ({ event, context }) => {
  const { db } = context;
  console.log("Queue Executed:", event.args);
  
  try {
    const queueId = event.args.queueId.toString();
    const nodeId = event.args.nodeId.toString();
    const network = context.network || getDefaultNetwork(context);
    const networkId = network.chainId.toString();
    const networkName = network.name.toLowerCase();
    
    // Find the queue first to see if it exists
    const existingQueue = await db.find(signatureQueues, { id: queueId });
    
    if (existingQueue) {
      // Update the existing queue to Executed state
      await db.update(signatureQueues, { id: queueId })
        .set({ state: "Executed" });
      
      console.log(`Updated signature queue ${queueId} to Executed state`);
    } else {
      console.log(`Queue ${queueId} not found, cannot update state`);
    }
    
    // Use the helper function to save the event
    await saveEvent({
      db,
      event,
      nodeId,
      who: event.args.executor,
      eventName: "QueueExecuted",
      eventType: "configSignal",
      network: network
    });
    
    // Record execution as a node signal
    await db.insert(nodeSignals).values({
      id: `${createEventId(event)}-queue-executed`,
      nodeId: nodeId,
      who: event.args.executor,
      signalType: "redistribution", // Closest signal type for governance actions
      signalValue: queueId,
      currentPrevalence: "0", // Not applicable for queue execution
      when: event.block.timestamp,
      network: networkName,
      networkId: networkId
    }).onConflictDoNothing();
    
    console.log(`Saved queue execution signal from ${event.args.executor}`);
  } catch (error) {
    console.error("Error in handleQueueExecuted:", error);
  }
};

export const handleNewSignaturesSubmitted = async ({ event, context }) => {
  const { db } = context;
  console.log("New Signatures Submitted:", event.args);
  
  try {
    const queueId = event.args.queueId.toString();
    const movementId = event.args.movementId.toString();
    const nodeId = event.args.nodeId.toString();
    const network = context.network || getDefaultNetwork(context);
    const networkId = network.chainId.toString();
    const networkName = network.name.toLowerCase();
    
    // Check if queue exists
    const existingQueue = await db.find(signatureQueues, { id: queueId });
    
    if (!existingQueue) {
      // Create new signature queue
      await db.insert(signatureQueues).values({
        id: queueId,
        state: "Initialized",
        movementId: movementId,
        signers: [],
        signatures: [],
        createdBlockNumber: event.block.number,
        network: networkName,
        networkId: networkId
      }).onConflictDoNothing();
      
      console.log("Created new signature queue:", queueId);
    }
    
    // Create a unique ID for the signature with fallback
    const signatureId = createEventId(event);
    
    // Add new signature
    await db.insert(signatures).values({
      id: signatureId,
      nodeId: nodeId,
      signer: event.args.signer,
      signature: event.args.signature,
      signatureQueueHash: queueId,
      submitted: true,
      when: event.block.timestamp,
      network: networkName,
      networkId: networkId
    }).onConflictDoNothing();
    
    console.log("Inserted signature:", signatureId);
    
    // Use the helper function to save the event
    await saveEvent({
      db,
      event,
      nodeId,
      who: event.args.signer,
      eventName: "NewSignaturesSubmitted",
      eventType: "configSignal",
      network: network
    });
    
    // Record signature as a node signal
    await db.insert(nodeSignals).values({
      id: `${createEventId(event)}-signature-submitted`,
      nodeId: nodeId,
      who: event.args.signer,
      signalType: "redistribution", // Closest signal type for governance actions
      signalValue: queueId,
      currentPrevalence: "0", // Not applicable for signature submission
      when: event.block.timestamp,
      network: networkName,
      networkId: networkId
    }).onConflictDoNothing();
    
    console.log(`Saved signature submission signal from ${event.args.signer}`);
  } catch (error) {
    console.error("Error in handleNewSignaturesSubmitted:", error);
  }
};

export const handleSignatureRemoved = async ({ event, context }) => {
  const { db } = context;
  console.log("Signature Removed:", event.args);
  
  try {
    const queueId = event.args.queueId.toString();
    const nodeId = event.args.nodeId.toString();
    const signer = event.args.signer;
    const network = context.network || getDefaultNetwork(context);
    const networkId = network.chainId.toString();
    const networkName = network.name.toLowerCase();
    
    // Find signatures matching this queue and signer
    const matchingSignatures = await db.select().from(signatures)
      .where('signatureQueueHash', '=', queueId)
      .where('signer', '=', signer)
      .execute();
    
    // Update each signature to set submitted = false
    for (const sig of matchingSignatures) {
      await db.update(signatures, { id: sig.id })
        .set({ submitted: false });
    }
    
    console.log(`Updated ${matchingSignatures.length} signatures to submitted=false`);
    
    // Use the helper function to save the event
    await saveEvent({
      db,
      event,
      nodeId,
      who: signer,
      eventName: "SignatureRemoved",
      eventType: "configSignal",
      network: network
    });
    
    // Record signature removal as a node signal
    await db.insert(nodeSignals).values({
      id: `${createEventId(event)}-signature-removed`,
      nodeId: nodeId,
      who: signer,
      signalType: "redistribution", // Closest signal type for governance actions
      signalValue: queueId,
      currentPrevalence: "0", // Not applicable for signature removal
      when: event.block.timestamp,
      network: networkName,
      networkId: networkId
    }).onConflictDoNothing();
    
    console.log(`Saved signature removal signal from ${signer}`);
  } catch (error) {
    console.error("Error in handleSignatureRemoved:", error);
  }
};

export const handleWillWeSet = async ({ event, context }) => {
  const { db } = context;
  console.log("WillWe Set:", event.args);
  
  try {
    const network = context.network || getDefaultNetwork(context);
    
    // Use the helper function to save the event
    await saveEvent({
      db,
      event,
      nodeId: "0", // Default nodeId
      who: event.args.setter || event.transaction.from,
      eventName: "WillWeSet",
      eventType: "configSignal",
      network: network
    });
    
    console.log(`Recorded WillWeSet event from ${event.args.setter || event.transaction.from}`);
  } catch (error) {
    console.error("Error in handleWillWeSet:", error);
  }
};
