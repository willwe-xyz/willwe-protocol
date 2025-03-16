// This file exports event handlers for Execution contract events
import { ponder } from "ponder:registry";
import { events, movements, signatureQueues, signatures, nodeSignals } from "../ponder.schema";
import { createEventId, saveEvent, getDefaultNetwork } from "./common";

export const handleNewMovementCreated = async ({ event, context }) => {
  const { db } = context;
  console.log("New Movement Created:", event.args);

  try {
    if (!event?.args?.nodeId) {
      console.error("Missing required nodeId in event args");
      return;
    }

    // Create a unique ID for the movement
    const movementId = (event.args.movementHash?.toString() || 
                        event.args.movementId?.toString() || 
                        `mov-${createEventId(event)}`);
    
    const nodeId = event.args.nodeId.toString();
    const network = context.network || getDefaultNetwork();
    const networkId = network.id.toString();
    const networkName = network.name.toLowerCase();
    
    // Insert the movement with safe defaults for missing fields
    await db.insert(movements).values({
      id: movementId,
      nodeId: nodeId,
      category: event.args.category === 0 ? "Revert" : event.args.category === 1 ? "AgentMajority" : "EnergeticMajority",
      initiator: event.args.initiator || event.transaction?.from || "unknown",
      exeAccount: event.args.exeAccount || event.args.initiator || event.transaction?.from || "unknown",
      viaNode: event.args.viaNode || 0,
      expiresAt: event.args.expiresAt || BigInt(event.block.timestamp) + BigInt(7 * 24 * 60 * 60), // 1 week default
      description: event.args.description || "",
      executedPayload: event.args.executedPayload || "",
      createdBlockNumber: event.block.number,
      network: networkName,
      networkId: networkId
    }).onConflictDoNothing();

    console.log("Inserted Movement:", movementId);
    
    // Use the helper function to save the event
    await saveEvent({
      db,
      event,
      nodeId,
      who: event.args.initiator || event.transaction?.from,
      eventName: "NewMovementCreated",
      eventType: "configSignal",
      network: network
    });
    
    // Also record as a node signal for historical tracking
    await db.insert(nodeSignals).values({
      id: `${createEventId(event)}-movement-created`,
      nodeId: nodeId,
      who: event.args.initiator || event.transaction?.from || "unknown",
      signalType: "redistribution", // Closest signal type for governance actions
      signalValue: movementId,
      currentPrevalence: "0", // Not applicable for movements
      when: event.block.timestamp,
      network: networkName,
      networkId: networkId
    }).onConflictDoNothing();
    
    console.log(`Saved movement creation signal from ${event.args.initiator || "unknown"}`);
  } catch (error) {
    console.error("Error in handleNewMovementCreated:", error);
  }
};

export const handleQueueExecuted = async ({ event, context }) => {
  const { db } = context;
  console.log("Queue Executed:", event.args);
  
  try {
    const queueId = event.args.queueId.toString();
    const nodeId = event.args.nodeId.toString();
    const network = context.network || getDefaultNetwork();
    const networkId = network.id.toString();
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
    const network = context.network || getDefaultNetwork();
    const networkId = network.id.toString();
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
    const network = context.network || getDefaultNetwork();
    const networkId = network.id.toString();
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
    const network = context.network || getDefaultNetwork();
    
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
