// This file exports event handlers for Execution contract events
import { ponder } from "ponder:registry";
import { events, movements, signatureQueues, signatures, nodeSignals } from "../ponder.schema";

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

export const handleNewMovementCreated = async ({ event, context }) => {
  const { db } = context;
  console.log("New Movement Created:", event.args);

  try {
    // Create a unique ID for the movement
    const movementId = event.args.movementId.toString();
    const nodeId = event.args.nodeId.toString();
    const network = context.network?.name?.toLowerCase() || "optimismsepolia";
    
    // Insert the movement
    await db.insert(movements).values({
      id: movementId,
      nodeId: nodeId,
      category: event.args.category === 0 ? "Revert" : event.args.category === 1 ? "AgentMajority" : "EnergeticMajority",
      initiator: event.args.initiator,
      exeAccount: event.args.exeAccount,
      viaNode: event.args.viaNode,
      expiresAt: event.args.expiresAt,
      description: event.args.description || "",
      executedPayload: event.args.executedPayload || "",
      createdBlockNumber: event.block.number,
      network: network
    }).onConflictDoNothing();

    console.log("Inserted Movement:", movementId);
    
    // Use the helper function to save the event
    await saveEvent({
      db,
      event,
      nodeId,
      who: event.args.initiator,
      eventName: "NewMovementCreated",
      eventType: "configSignal"
    });
    
    // Also record as a node signal for historical tracking
    await db.insert(nodeSignals).values({
      id: `${createEventId(event)}-movement-created`,
      nodeId: nodeId,
      who: event.args.initiator,
      signalType: "redistribution", // Closest signal type for governance actions
      signalValue: movementId,
      currentPrevalence: "0", // Not applicable for movements
      when: event.block.timestamp,
      network: network
    }).onConflictDoNothing();
    
    console.log(`Saved movement creation signal from ${event.args.initiator}`);
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
    const network = context.network?.name?.toLowerCase() || "optimismsepolia";
    
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
      eventType: "configSignal"
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
      network: network
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
    const network = context.network?.name?.toLowerCase() || "optimismsepolia";
    
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
        network: network
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
      network: network
    }).onConflictDoNothing();
    
    console.log("Inserted signature:", signatureId);
    
    // Use the helper function to save the event
    await saveEvent({
      db,
      event,
      nodeId,
      who: event.args.signer,
      eventName: "NewSignaturesSubmitted",
      eventType: "configSignal"
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
      network: network
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
    const network = context.network?.name?.toLowerCase() || "optimismsepolia";
    
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
      eventType: "configSignal"
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
      network: network
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
    // Use the helper function to save the event
    await saveEvent({
      db,
      event,
      nodeId: "0", // Default nodeId
      who: event.args.setter || event.transaction.from,
      eventName: "WillWeSet",
      eventType: "configSignal"
    });
    
    console.log(`Recorded WillWeSet event from ${event.args.setter || event.transaction.from}`);
  } catch (error) {
    console.error("Error in handleWillWeSet:", error);
  }
};
