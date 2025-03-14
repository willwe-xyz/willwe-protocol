// This file exports event handlers for Execution contract events
import { ponder } from "ponder:registry";
import { events, movements, signatureQueues, signatures } from "../ponder.schema";

export const handleNewMovementCreated = async ({ event, context }) => {
  const { db } = context;
  console.log("New Movement Created:", event.args);

  try {
    // Create a unique ID for the movement
    const movementId = event.args.movementId.toString();
    const nodeId = event.args.nodeId.toString();
    
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
      network: context.network.name.toLowerCase()
    }).onConflictDoNothing();

    console.log("Inserted Movement:", movementId);
    
    // Create a unique ID for the event with fallback
    const transactionHash = event.transaction?.hash || `tx-${event.block.hash}-${event.block.number}`;
    const eventId = `${transactionHash}-${event.log.logIndex}`;
    
    // Insert the event
    await db.insert(events).values({
      id: eventId,
      nodeId: nodeId,
      who: event.args.initiator,
      eventName: "NewMovementCreated",
      eventType: "configSignal",
      when: event.block.timestamp,
      createdBlockNumber: event.block.number,
      network: context.network.name.toLowerCase()
    }).onConflictDoNothing();
    
    console.log("Inserted NewMovementCreated event:", eventId);
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
    
    // Create a unique ID for the event with fallback
    const transactionHash = event.transaction?.hash || `tx-${event.block.hash}-${event.block.number}`;
    const eventId = `${transactionHash}-${event.log.logIndex}`;
    
    // Insert the event
    await db.insert(events).values({
      id: eventId,
      nodeId: nodeId,
      who: event.args.executor,
      eventName: "QueueExecuted",
      eventType: "configSignal", 
      when: event.block.timestamp,
      createdBlockNumber: event.block.number,
      network: context.network.name.toLowerCase()
    }).onConflictDoNothing();
    
    console.log("Inserted QueueExecuted event:", eventId);
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
        network: context.network.name.toLowerCase()
      }).onConflictDoNothing();
      
      console.log("Created new signature queue:", queueId);
    }
    
    // Create a unique ID for the signature with fallback
    const transactionHash = event.transaction?.hash || `tx-${event.block.hash}-${event.block.number}`;
    const signatureId = `${transactionHash}-${event.log.logIndex}`;
    
    // Add new signature
    await db.insert(signatures).values({
      id: signatureId,
      nodeId: nodeId,
      signer: event.args.signer,
      signature: event.args.signature,
      signatureQueueHash: queueId,
      submitted: true,
      when: event.block.timestamp,
      network: context.network.name.toLowerCase()
    }).onConflictDoNothing();
    
    console.log("Inserted signature:", signatureId);
    
    // Create a unique ID for the event
    const eventId = `${transactionHash}-${event.log.logIndex}`;
    
    // Insert the event
    await db.insert(events).values({
      id: eventId,
      nodeId: nodeId,
      who: event.args.signer,
      eventName: "NewSignaturesSubmitted",
      eventType: "configSignal",
      when: event.block.timestamp,
      createdBlockNumber: event.block.number,
      network: context.network.name.toLowerCase()
    }).onConflictDoNothing();
    
    console.log("Inserted NewSignaturesSubmitted event:", eventId);
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
    
    // Create a unique ID for the event with fallback
    const transactionHash = event.transaction?.hash || `tx-${event.block.hash}-${event.block.number}`;
    const eventId = `${transactionHash}-${event.log.logIndex}`;
    
    // Find signatures matching this queue and signer
    const signatures = await db.select().from(signatures)
      .where('signatureQueueHash', '=', queueId)
      .where('signer', '=', signer)
      .execute();
    
    // Update each signature to set submitted = false
    for (const sig of signatures) {
      await db.update(signatures, { id: sig.id })
        .set({ submitted: false });
    }
    
    console.log(`Updated ${signatures.length} signatures to submitted=false`);
    
    // Insert the event
    await db.insert(events).values({
      id: eventId,
      nodeId: nodeId,
      who: signer,
      eventName: "SignatureRemoved",
      eventType: "configSignal",
      when: event.block.timestamp,
      createdBlockNumber: event.block.number,
      network: context.network.name.toLowerCase()
    }).onConflictDoNothing();
    
    console.log("Inserted SignatureRemoved event:", eventId);
  } catch (error) {
    console.error("Error in handleSignatureRemoved:", error);
  }
};

export const handleWillWeSet = async ({ event, context }) => {
  const { db } = context;
  console.log("WillWe Set:", event.args);
  
  try {
    // Create a unique ID for the event with fallback
    const transactionHash = event.transaction?.hash || `tx-${event.block.hash}-${event.block.number}`;
    const eventId = `${transactionHash}-${event.log.logIndex}`;
    
    // Insert the event
    await db.insert(events).values({
      id: eventId,
      nodeId: "0", // Default nodeId
      who: event.args.setter,
      eventName: "WillWeSet",
      eventType: "configSignal",
      when: event.block.timestamp,
      createdBlockNumber: event.block.number,
      network: context.network.name.toLowerCase()
    }).onConflictDoNothing();
    
    console.log("Inserted WillWeSet event:", eventId);
  } catch (error) {
    console.error("Error in handleWillWeSet:", error);
  }
};
