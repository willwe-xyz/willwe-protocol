// This file exports event handlers for WillWe contract events
import { ponder } from "ponder:registry";
import { events, memberships, nodes, endpoints, nodeSignals } from "../ponder.schema";
import { createPublicClient, http } from "viem";
import { supportedChains } from "../ponder.config";

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

// Helper function to get the appropriate public client for a network
const getPublicClient = (network) => {
  // Default to optimismSepolia if network is not provided
  const networkName = network || "optimismSepolia";
  
  // Find the chain config by name or chain ID
  const chainId = typeof networkName === 'string' 
    ? supportedChains.find(chain => chain.name.toLowerCase() === networkName.toLowerCase())?.id
    : networkName;
  
  // Find the chain by ID if we have a numeric chainId
  const chain = supportedChains.find(chain => chain.id === chainId) || supportedChains.find(chain => chain.name.toLowerCase() === "optimismsepolia");
  
  if (!chain) {
    console.error(`Chain not found for network: ${networkName}, defaulting to optimismSepolia`);
    return null;
  }
  
  // Get the RPC URL from environment variable
  const rpcUrl = process.env[`PONDER_RPC_URL_${chain.id}`] || "https://sepolia.optimism.io";
  
  // Create and return the public client
  return createPublicClient({
    chain,
    transport: http(rpcUrl)
  });
};

// Helper function to get signal prevalence from contract
const getSignalPrevalence = async (nodeId, signalValue, contractAddress, network) => {
  try {
    const client = getPublicClient(network);
    
    if (!client) {
      console.error("Failed to create client for network:", network);
      return "0";
    }
    
    const prevalence = await client.readContract({
      address: contractAddress,
      abi: [
        {
          name: "getChangePrevalence",
          type: "function",
          stateMutability: "view",
          inputs: [
            { name: "nodeId_", type: "uint256" },
            { name: "signal_", type: "uint256" }
          ],
          outputs: [{ type: "uint256" }]
        }
      ],
      functionName: "getChangePrevalence",
      args: [BigInt(nodeId), BigInt(signalValue)]
    });
    
    return prevalence.toString();
  } catch (error) {
    console.error("Error getting signal prevalence:", error);
    return "0";
  }
};

export async function handleNewRootNode({ event, context }) {
  const { db } = context;
  console.log("New Root Node created:", event.args);

  try {
    // Create a unique ID for the node
    const nodeId = event.args.rootNodeId.toString();
    
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
    
    // Use the helper function to save the event
    await saveEvent({
      db,
      event,
      nodeId,
      who: event.args.creator || event.transaction.from,
      eventName: "NewRootNode",
      eventType: "mint"
    });
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
    
    // Use the helper function to save the event
    await saveEvent({
      db,
      event,
      nodeId,
      who: event.args.creator,
      eventName: "NewNode",
      eventType: "mint"
    });
  } catch (error) {
    console.error("Error in handleNewNode:", error);
  }
}

export async function handleMembershipMinted({ event, context }) {
  const { db } = context;
  console.log("Membership Minted:", event.args);
  
  try {
    // Create a unique ID for the membership using proper fallback for transaction hash
    const membershipId = createEventId(event);
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
    
    // Use the helper function to save the event
    await saveEvent({
      db,
      event,
      nodeId,
      who: event.args.who,
      eventName: "MembershipMinted",
      eventType: "mint"
    });
  } catch (error) {
    console.error("Error in handleMembershipMinted:", error);
  }
}

export async function handleTransferSingle({ event, context }) {
  const { db } = context;
  console.log("Transfer Single:", event.args);
  
  try {
    const nodeId = event.args.id.toString();
    
    // Use the helper function to save the event
    await saveEvent({
      db,
      event,
      nodeId,
      who: event.args.to,
      eventName: "TransferSingle",
      eventType: "transfer"
    });
  } catch (error) {
    console.error("Error in handleTransferSingle:", error);
  }
}

export async function handleTransferBatch({ event, context }) {
  const { db } = context;
  console.log("Transfer Batch:", event.args);
  
  try {
    // For each ID in the batch
    for (let i = 0; i < event.args.ids.length; i++) {
      const nodeId = event.args.ids[i].toString();
      
      // Use the helper function to save the event
      await saveEvent({
        db,
        event: {
          ...event,
          log: {
            ...event.log,
            logIndex: event.log.logIndex + `-${i}` // Make unique IDs for each item in batch
          }
        },
        nodeId,
        who: event.args.to,
        eventName: "TransferBatch",
        eventType: "transfer"
      });
    }
  } catch (error) {
    console.error("Error in handleTransferBatch:", error);
  }
}

export async function handleUserNodeSignal({ event, context }) {
  const { db } = context;
  console.log("User Node Signal:", event.args);
  
  try {
    const nodeId = event.args.nodeId.toString();
    const user = event.args.user;
    const signals = event.args.signals || [];
    
    // Use the helper function to save the event
    await saveEvent({
      db,
      event,
      nodeId,
      who: user,
      eventName: "UserNodeSignal",
      eventType: "configSignal"
    });
    
    // Process the signals array
    // In the signals array, [0] is membrane signal, [1] is inflation signal
    if (signals.length > 0) {
      const contractAddress = event.log.address;
      const network = context.network?.name || "optimismSepolia";
      
      // Handle membrane signal (index 0)
      const membraneSignal = signals[0]?.toString();
      if (membraneSignal && membraneSignal !== "0") {
        const membranePrevalence = await getSignalPrevalence(
          nodeId, 
          membraneSignal, 
          contractAddress, 
          network
        );
        
        // Save as nodeSignal
        await db.insert(nodeSignals).values({
          id: `${createEventId(event)}-membrane`,
          nodeId: nodeId,
          who: user,
          signalType: "membrane",
          signalValue: membraneSignal,
          currentPrevalence: membranePrevalence,
          when: event.block.timestamp,
          network: network.toLowerCase()
        }).onConflictDoNothing();
        
        console.log(`Inserted membrane signal for node ${nodeId} from ${user}`);
      }
      
      // Handle inflation signal (index 1)
      const inflationSignal = signals[1]?.toString();
      if (inflationSignal && inflationSignal !== "0") {
        const inflationPrevalence = await getSignalPrevalence(
          nodeId, 
          inflationSignal, 
          contractAddress, 
          network
        );
        
        // Save as nodeSignal
        await db.insert(nodeSignals).values({
          id: `${createEventId(event)}-inflation`,
          nodeId: nodeId,
          who: user,
          signalType: "inflation",
          signalValue: inflationSignal,
          currentPrevalence: inflationPrevalence,
          when: event.block.timestamp,
          network: network.toLowerCase()
        }).onConflictDoNothing();
        
        console.log(`Inserted inflation signal for node ${nodeId} from ${user}`);
      }
      
      // Check if there are redistribution preferences (rest of the array)
      if (signals.length > 2) {
        const redistributionSignals = signals.slice(2);
        
        // Save as nodeSignal with array of redistributionSignals
        await db.insert(nodeSignals).values({
          id: `${createEventId(event)}-redistribution`,
          nodeId: nodeId,
          who: user,
          signalType: "redistribution",
          signalValue: JSON.stringify(redistributionSignals),
          currentPrevalence: "0", // Not applicable for redistribution
          when: event.block.timestamp,
          network: context.network.name.toLowerCase()
        }).onConflictDoNothing();
        
        console.log(`Inserted redistribution signals for node ${nodeId} from ${user}`);
      }
    }
  } catch (error) {
    console.error("Error in handleUserNodeSignal:", error);
  }
}

export async function handleConfigSignal({ event, context }) {
  const { db } = context;
  console.log("Config Signal:", event.args);
  
  try {
    const nodeId = event.args.nodeId.toString();
    const expressedOption = event.args.expressedOption;
    const who = event.args.origin || event.transaction.from;
    
    // Use the helper function to save the event
    await saveEvent({
      db,
      event,
      nodeId,
      who,
      eventName: "ConfigSignal",
      eventType: "configSignal"
    });
    
    // Since ConfigSignal is more general, we are recording it in the events table only
    // The specific signals (membrane, inflation, redistribution) are recorded by the handleUserNodeSignal handler
    console.log(`Recorded config signal for node ${nodeId} from ${who}`);
  } catch (error) {
    console.error("Error in handleConfigSignal:", error);
  }
}

export async function handleCreatedEndpoint({ event, context }) {
  const { db } = context;
  console.log("Created Endpoint:", event.args);
  
  try {
    // Create a unique ID for the endpoint with fallback
    const endpointId = createEventId(event);
    const nodeId = event.args.nodeId.toString();
    
    // Insert the endpoint
    await db.insert(endpoints).values({
      id: endpointId,
      nodeId: event.args.nodeId,
      endpointId: event.args.endpointId || 0,
      owner: event.args.owner,
      endpointType: event.args.endpointType === 0 ? "userOwned" : "movement",
      endpointAddress: event.args.endpoint,
      createdAt: event.block.timestamp,
      createdBlockNumber: event.block.number,
      network: context.network.name.toLowerCase()
    }).onConflictDoNothing();

    console.log("Inserted endpoint:", endpointId);
    
    // Use the helper function to save the event
    await saveEvent({
      db,
      event,
      nodeId,
      who: event.args.owner,
      eventName: "CreatedEndpoint",
      eventType: "configSignal"
    });
  } catch (error) {
    console.error("Error in handleCreatedEndpoint:", error);
  }
}

export async function handleMembraneChanged({ event, context }) {
  const { db } = context;
  console.log("Membrane Changed:", event.args);
  
  try {
    const nodeId = event.args.nodeId.toString();
    const newMembraneId = event.args.newMembrane.toString();
    const previousMembraneId = event.args.previousMembrane.toString();
    
    // Update the node's membrane ID - using correct update syntax for Ponder
    await db.update(nodes, { nodeId: nodeId })
      .set({ 
        membraneId: newMembraneId,
        updatedAt: event.block.timestamp 
      });
      
    // Use the helper function to save the event
    await saveEvent({
      db,
      event,
      nodeId,
      who: event.transaction.from,
      eventName: "MembraneChanged",
      eventType: "membraneSignal"
    });
    
    // Save a signal record for historical tracking
    // This captures the successful membrane change (not just a signal)
    await db.insert(nodeSignals).values({
      id: `${createEventId(event)}-membrane-change`,
      nodeId: nodeId,
      who: event.transaction.from,
      signalType: "membrane",
      signalValue: newMembraneId,
      currentPrevalence: "0", // The change has been applied, so prevalence is reset
      when: event.block.timestamp,
      network: context.network?.name?.toLowerCase() || "optimismsepolia"
    }).onConflictDoNothing();
    
    console.log(`Recorded membrane change for node ${nodeId}: ${previousMembraneId} -> ${newMembraneId}`);
  } catch (error) {
    console.error("Error in handleMembraneChanged:", error);
  }
}

export async function handleInflationRateChanged({ event, context }) {
  const { db } = context;
  console.log("Inflation Rate Changed:", event.args);
  
  try {
    const nodeId = event.args.nodeId.toString();
    const newInflationRate = event.args.newInflationRate.toString();
    const oldInflationRate = event.args.oldInflationRate.toString();
    
    // Update the node's inflation rate - using correct update syntax for Ponder
    await db.update(nodes, { nodeId: nodeId })
      .set({ 
        inflation: newInflationRate,
        updatedAt: event.block.timestamp 
      });
      
    // Use the helper function to save the event
    await saveEvent({
      db,
      event,
      nodeId,
      who: event.transaction.from,
      eventName: "InflationRateChanged",
      eventType: "inflationRateChanged"
    });
    
    // Save a signal record for historical tracking
    // This captures the successful inflation rate change (not just a signal)
    await db.insert(nodeSignals).values({
      id: `${createEventId(event)}-inflation-change`,
      nodeId: nodeId,
      who: event.transaction.from,
      signalType: "inflation",
      signalValue: newInflationRate,
      currentPrevalence: "0", // The change has been applied, so prevalence is reset
      when: event.block.timestamp,
      network: context.network?.name?.toLowerCase() || "optimismsepolia"
    }).onConflictDoNothing();
    
    console.log(`Recorded inflation rate change for node ${nodeId}: ${oldInflationRate} -> ${newInflationRate}`);
  } catch (error) {
    console.error("Error in handleInflationRateChanged:", error);
  }
}

export async function handleSharesGenerated({ event, context }) {
  const { db } = context;
  console.log("Shares Generated:", event.args);
  
  try {
    const nodeId = event.args.nodeId.toString();
    
    // Update the node with correct update syntax for Ponder
    await db.update(nodes, { nodeId: nodeId })
      .set({ 
        lastRedistributionTime: event.block.timestamp.toString(),
        updatedAt: event.block.timestamp 
      });
      
    // Use the helper function to save the event
    await saveEvent({
      db,
      event,
      nodeId,
      who: event.transaction.from,
      eventName: "SharesGenerated",
      eventType: "inflationMinted"
    });
  } catch (error) {
    console.error("Error in handleSharesGenerated:", error);
  }
}

export async function handleMinted({ event, context }) {
  const { db } = context;
  console.log("Minted:", event.args);
  
  try {
    const nodeId = event.args.nodeId.toString();
    
    // Update the node's total supply using correct db methods
    const node = await db.find(nodes, { nodeId: nodeId });
      
    if (node) {
      const currentSupply = BigInt(node.totalSupply || '0');
      const newAmount = BigInt(event.args.amount.toString());
      const newTotal = (currentSupply + newAmount).toString();
      
      await db.update(nodes, { nodeId: nodeId })
        .set({ 
          totalSupply: newTotal,
          updatedAt: event.block.timestamp 
        });
    }
      
    // Use the helper function to save the event
    await saveEvent({
      db,
      event,
      nodeId,
      who: event.args.fromAddressOrNode,
      eventName: "Minted",
      eventType: "mint"
    });
  } catch (error) {
    console.error("Error in handleMinted:", error);
  }
}

export async function handleBurned({ event, context }) {
  const { db } = context;
  console.log("Burned:", event.args);
  
  try {
    const nodeId = event.args.nodeId.toString();
    
    // Update the node's total supply using correct db methods
    const node = await db.find(nodes, { nodeId: nodeId });
      
    if (node) {
      const currentSupply = BigInt(node.totalSupply || '0');
      const burnAmount = BigInt(event.args.amount.toString());
      const newTotal = currentSupply > burnAmount ? (currentSupply - burnAmount).toString() : '0';
      
      await db.update(nodes, { nodeId: nodeId })
        .set({ 
          totalSupply: newTotal,
          updatedAt: event.block.timestamp 
        });
    }
      
    // Use the helper function to save the event
    await saveEvent({
      db,
      event,
      nodeId,
      who: event.args.fromAddressOrNode,
      eventName: "Burned",
      eventType: "burn"
    });
  } catch (error) {
    console.error("Error in handleBurned:", error);
  }
}

export async function handleSignaled({ event, context }) {
  const { db } = context;
  console.log("Signaled:", event.args);
  
  try {
    const nodeId = event.args.nodeId.toString();
    const sender = event.args.sender;
    const origin = event.args.origin;
    
    // Use the helper function to save the event
    await saveEvent({
      db,
      event,
      nodeId,
      who: sender,
      eventName: "Signaled",
      eventType: "configSignal"
    });
    
    // This is a general signal event that we record in the events table
    console.log(`Recorded signal event for node ${nodeId} from ${sender}, origin: ${origin}`);
  } catch (error) {
    console.error("Error in handleSignaled:", error);
  }
}

export async function handleResignaled({ event, context }) {
  const { db } = context;
  console.log("Resignaled:", event.args);
  
  try {
    const nodeId = event.args.nodeId.toString();
    const from = event.args.from || event.transaction.from;
    
    // Use the helper function to save the event
    await saveEvent({
      db,
      event,
      nodeId,
      who: from,
      eventName: "Resignaled",
      eventType: "configSignal"
    });
    
    console.log(`Recorded resignal event for node ${nodeId} from ${from}`);
  } catch (error) {
    console.error("Error in handleResignaled:", error);
  }
}
