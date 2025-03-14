// This file contains event handlers for WillWe contract events
import { ponder } from "ponder:registry";
import { events, memberships, nodes, endpoints } from "../ponder.schema";

export async function handleNewRootNode({ event, context }) {
  const { db } = context;
  console.log("New Root Node created:", event.args);

  try {
    // Create a unique ID for the node
    const nodeId = event.args.newId.toString();
    
    // Insert the new root node
    await db.insert(nodes).values({
      nodeId: nodeId,
      inflation: "0",
      reserve: "0",
      budget: "0",
      rootValuationBudget: "0",
      rootValuationReserve: "0",
      membraneId: "0",
      eligibilityPerSec: "0",
      lastRedistributionTime: "0",
      totalSupply: "0",
      membraneMeta: "",
      membersOfNode: [],
      childrenNodes: [],
      movementEndpoints: [],
      rootPath: [],
      signals: [],
      createdAt: event.block.timestamp,
      updatedAt: event.block.timestamp,
      createdBlockNumber: event.block.number,
      network: context.network.name.toLowerCase()
    }).onConflictDoUpdate({
      updatedAt: event.block.timestamp
    });

    console.log("Inserted/Updated Root Node:", nodeId);
    
    // Create a unique ID for the event, using hash and logIndex
    // Handle potential undefined case by using a fallback
    const transactionHash = event.transaction?.hash || `tx-${event.block.hash}-${event.block.number}`;
    const eventId = `${transactionHash}-${event.log.logIndex}`;
    
    // Insert the event
    await db.insert(events).values({
      id: eventId,
      nodeId: nodeId,
      who: event.args.creator,
      eventName: "NewRootNode",
      eventType: "mint",
      when: event.block.timestamp,
      createdBlockNumber: event.block.number,
      network: context.network.name.toLowerCase()
    }).onConflictDoNothing();

    console.log("Inserted NewRootNode event:", eventId);
  } catch (error) {
    console.error("Error in handleNewRootNode:", error);
  }
}

export async function handleNewNode({ event, context }) {
  const { db } = context;
  console.log("New Node created:", event.args);
  
  try {
    // Create a unique ID for the node
    const nodeId = event.args.newId.toString();
    
    // Insert the new node
    await db.insert(nodes).values({
      nodeId: nodeId,
      inflation: "0",
      reserve: "0",
      budget: "0",
      rootValuationBudget: "0",
      rootValuationReserve: "0",
      membraneId: "0",
      eligibilityPerSec: "0",
      lastRedistributionTime: "0",
      totalSupply: "0",
      membraneMeta: "",
      membersOfNode: [],
      childrenNodes: [],
      movementEndpoints: [],
      rootPath: [],
      signals: [],
      createdAt: event.block.timestamp,
      updatedAt: event.block.timestamp,
      createdBlockNumber: event.block.number,
      network: context.network.name.toLowerCase()
    }).onConflictDoUpdate({
      updatedAt: event.block.timestamp
    });

    console.log("Inserted/Updated Node:", nodeId);
    
    // Create a unique ID for the event, using hash and logIndex
    // Handle potential undefined case by using a fallback
    const transactionHash = event.transaction?.hash || `tx-${event.block.hash}-${event.block.number}`;
    const eventId = `${transactionHash}-${event.log.logIndex}`;
    
    // Insert the event
    await db.insert(events).values({
      id: eventId,
      nodeId: nodeId,
      who: event.args.creator,
      eventName: "NewNode",
      eventType: "mint",
      when: event.block.timestamp,
      createdBlockNumber: event.block.number,
      network: context.network.name.toLowerCase()
    }).onConflictDoNothing();

    console.log("Inserted NewNode event:", eventId);
  } catch (error) {
    console.error("Error in handleNewNode:", error);
  }
}

// For the remaining event handlers, just modifying the event ID generation and keeping other code the same

export async function handleMembershipMinted({ event, context }) {
  const { db } = context;
  console.log("Membership Minted:", event.args);
  
  try {
    // Create a unique ID for the membership using proper fallback for transaction hash
    const transactionHash = event.transaction?.hash || `tx-${event.block.hash}-${event.block.number}`;
    const membershipId = `${transactionHash}-${event.log.logIndex}`;
    const nodeId = event.args.nodeId.toString();
    
    // Insert the new membership
    await db.insert(memberships).values({
      id: membershipId,
      nodeId: nodeId,
      who: event.args.who,
      when: event.block.timestamp,
      isValid: true
    }).onConflictDoNothing();

    console.log("Inserted Membership:", membershipId);
    
    // Create a unique ID for the event
    const eventId = `${transactionHash}-${event.log.logIndex}`;
    
    // Insert the event
    await db.insert(events).values({
      id: eventId,
      nodeId: nodeId,
      who: event.args.who,
      eventName: "MembershipMinted",
      eventType: "mint",
      when: event.block.timestamp,
      createdBlockNumber: event.block.number,
      network: context.network.name.toLowerCase()
    }).onConflictDoNothing();
    
  } catch (error) {
    console.error("Error in handleMembershipMinted:", error);
  }
}

export async function handleTransferSingle({ event, context }) {
  const { db } = context;
  console.log("Transfer Single:", event.args);
  
  try {
    // Create a unique ID for the event using proper fallback
    const transactionHash = event.transaction?.hash || `tx-${event.block.hash}-${event.block.number}`;
    const eventId = `${transactionHash}-${event.log.logIndex}`;
    const nodeId = event.args.id.toString();
    
    // Insert the event
    await db.insert(events).values({
      id: eventId,
      nodeId: nodeId,
      who: event.args.to,
      eventName: "TransferSingle",
      eventType: "transfer",
      when: event.block.timestamp,
      createdBlockNumber: event.block.number,
      network: context.network.name.toLowerCase()
    }).onConflictDoNothing();

    console.log("Inserted TransferSingle event:", eventId);
  } catch (error) {
    console.error("Error in handleTransferSingle:", error);
  }
}

export async function handleTransferBatch({ event, context }) {
  const { db } = context;
  console.log("Transfer Batch:", event.args);
  
  try {
    // Create a unique transaction hash with fallback
    const transactionHash = event.transaction?.hash || `tx-${event.block.hash}-${event.block.number}`;
    
    // For each ID in the batch
    for (let i = 0; i < event.args.ids.length; i++) {
      // Create a unique ID for each event in the batch
      const eventId = `${transactionHash}-${event.log.logIndex}-${i}`;
      const nodeId = event.args.ids[i].toString();
      
      // Insert the event
      await db.insert(events).values({
        id: eventId,
        nodeId: nodeId,
        who: event.args.to,
        eventName: "TransferBatch",
        eventType: "transfer",
        when: event.block.timestamp,
        createdBlockNumber: event.block.number,
        network: context.network.name.toLowerCase()
      }).onConflictDoNothing();
    }

    console.log("Inserted TransferBatch events");
  } catch (error) {
    console.error("Error in handleTransferBatch:", error);
  }
}

export async function handleUserNodeSignal({ event, context }) {
  const { db } = context;
  console.log("User Node Signal:", event.args);
  
  try {
    // Create a unique ID for the event with fallback
    const transactionHash = event.transaction?.hash || `tx-${event.block.hash}-${event.block.number}`;
    const eventId = `${transactionHash}-${event.log.logIndex}`;
    const nodeId = event.args.nodeId.toString();
    
    // Insert the event
    await db.insert(events).values({
      id: eventId,
      nodeId: nodeId,
      who: event.args.who,
      eventName: "UserNodeSignal",
      eventType: "configSignal",
      when: event.block.timestamp,
      createdBlockNumber: event.block.number,
      network: context.network.name.toLowerCase()
    }).onConflictDoNothing();

    console.log("Inserted UserNodeSignal event:", eventId);
  } catch (error) {
    console.error("Error in handleUserNodeSignal:", error);
  }
}

export async function handleConfigSignal({ event, context }) {
  const { db } = context;
  console.log("Config Signal:", event.args);
  
  try {
    // Create a unique ID for the event with fallback
    const transactionHash = event.transaction?.hash || `tx-${event.block.hash}-${event.block.number}`;
    const eventId = `${transactionHash}-${event.log.logIndex}`;
    const nodeId = event.args.nodeId.toString();
    
    // Insert the event
    await db.insert(events).values({
      id: eventId,
      nodeId: nodeId,
      who: event.args.who,
      eventName: "ConfigSignal",
      eventType: "configSignal",
      when: event.block.timestamp,
      createdBlockNumber: event.block.number,
      network: context.network.name.toLowerCase()
    }).onConflictDoNothing();

    console.log("Inserted ConfigSignal event:", eventId);
  } catch (error) {
    console.error("Error in handleConfigSignal:", error);
  }
}

export async function handleCreatedEndpoint({ event, context }) {
  const { db } = context;
  console.log("Created Endpoint:", event.args);
  
  try {
    // Create a unique ID for the endpoint with fallback
    const transactionHash = event.transaction?.hash || `tx-${event.block.hash}-${event.block.number}`;
    const endpointId = `${transactionHash}-${event.log.logIndex}`;
    const nodeId = event.args.nodeId.toString();
    
    // Insert the endpoint
    await db.insert(endpoints).values({
      id: endpointId,
      nodeId: event.args.nodeId,
      endpointId: event.args.endpointId,
      owner: event.args.owner,
      endpointType: event.args.endpointType === 0 ? "userOwned" : "movement",
      endpointAddress: event.args.endpoint,
      createdAt: event.block.timestamp,
      createdBlockNumber: event.block.number,
      network: context.network.name.toLowerCase()
    }).onConflictDoNothing();

    console.log("Inserted endpoint:", endpointId);
    
    // Create a unique ID for the event
    const eventId = `${transactionHash}-${event.log.logIndex}`;
    
    // Insert the event
    await db.insert(events).values({
      id: eventId,
      nodeId: nodeId,
      who: event.args.owner,
      eventName: "CreatedEndpoint",
      eventType: "configSignal",
      when: event.block.timestamp,
      createdBlockNumber: event.block.number,
      network: context.network.name.toLowerCase()
    }).onConflictDoNothing();
    
  } catch (error) {
    console.error("Error in handleCreatedEndpoint:", error);
  }
}
