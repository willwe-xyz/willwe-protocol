// This file exports event handlers for WillWe contract events
import { ponder, type Event, type Context } from "ponder:registry";
import { events, memberships, nodes, endpoints, nodeSignals, inflationSignals, EventType } from "../ponder.schema";
import { createPublicClient, formatEther, http } from "viem";
import { supportedChains } from "../ponder.config";
import { NodeState } from "./types";
import { ABIs, deployments } from "../abis/abi";
import viem from "viem";
import { safeBigIntStringify, safeEventArg, safeEventArgString, createEventId, saveEvent, getNodeData, getPublicClient, getRootNodeId } from './common';
import { root } from "viem/chains";
import { and, eq } from "drizzle-orm";

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

// Helper function to create a unique event ID
interface EventWithTransaction {
  transaction?: {
    hash: string;
  };
  block: {
    hash: string;
    number: number;
  };
  log: {
    logIndex: number | string;
  };
}



// Helper function to ensure a node exists before updating it
const ensureNodeExists = async (db, nodeId, timestamp, networkName, networkId) => {
  try {
    // Check if node exists
    const existingNode = await db.find(nodes, { nodeId });
    
    if (!existingNode) {
      console.log(`Node ${nodeId} not found, creating basic record first`);
      // Create a basic node record if it doesn't exist
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
        createdAt: timestamp,
        updatedAt: timestamp,
        createdBlockNumber: 0, // We don't have this info in this context
        network: networkName,
        networkId: networkId
      });
      return true;
    }
    return false;
  } catch (error) {
    console.error(`Error ensuring node ${nodeId} exists:`, error);
    return false;
  }
};


export async function handleNewRootNode({ event, context }) {
  const { db } = context;
  console.log("New Root Node created:", safeBigIntStringify(event.args || {}));

  try {
    // Check if required properties exist
    if (!event?.args) {
      console.error("Missing args in NewRootNode event");
      return;
    }
    
    // Try to safely extract rootNodeId from different possible formats
    let nodeId;
    try {
      // First check if rootNodeId exists
      if (event.args.rootNodeId === undefined || event.args.rootNodeId === null) {
        console.error("Missing rootNodeId in NewRootNode event args");
        return;
      }
      
      // Try to convert to string, but with fallback for errors
      nodeId = safeToString(event.args.rootNodeId);
      console.log(`Successfully extracted rootNodeId: ${nodeId}`);
    } catch (error) {
      console.error(`Error extracting rootNodeId: ${error.message}`);
      console.error("Event args:", safeBigIntStringify(event.args));
      return;
    }
    
    // Network info with fallbacks
    const networkName = context.network?.name?.toLowerCase() || "base-mainnet";
    const networkId = context.network?.chainId.toString() || "5432";
    
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
      network: networkName,
      networkId: networkId
    }).onConflictDoUpdate({
      target: nodes.nodeId,
      set: {
        updatedAt: event.block.timestamp
      }
    });

    console.log("Inserted/Updated Root Node:", nodeId);
    
    // Safely get creator with fallback
    const creator = event.args.creator || event.transaction?.from || "unknown";
    
    // Save the event
    await db.insert(events).values({
      id: createEventId(event),
      nodeId: nodeId,
      who: creator,
      eventName: "NewRootNode",
      eventType: "newRoot",
      when: event.block.timestamp,
      createdBlockNumber: event.block.number,
      networkId: networkId,
      network: networkName
    }).onConflictDoNothing();
    
    console.log(`Saved NewRootNode event for node ${nodeId}`);
  } catch (error) {
    console.error(`Error in handleNewRootNode: ${error.message}`);
    console.error("Full event args:", safeBigIntStringify(event?.args || {}));
    console.error("Stack trace:", error.stack);
  }
}

export async function handleNewNode({ event, context }) {
  const { db, client } = context;
  console.log("New Node created:", safeBigIntStringify(event.args || {}));

  try {
    // Safely get the nodeId from event.args
    if (!event?.args) {
      console.error("Missing args in NewNode event");
      return;
    }
    
    // Check for missing newId
    if (event.args.newId === undefined || event.args.newId === null) {
      console.error("Missing newId in NewNode event args");
      return;
    }
    
    // Convert newId to string safely
    let nodeId;
    try {
      nodeId = safeToString(event.args.newId);
      console.log(`Successfully extracted nodeId: ${nodeId}`);
    } catch (error) {
      console.error(`Error converting newId to string: ${error.message}`);
      console.error("Full event args:", safeBigIntStringify(event.args));
      return;
    }
    
    // Safely get parent ID if it exists
    let parentId = null;
    try {
      parentId = event.args.parentId ? safeToString(event.args.parentId) : null;
    } catch (error) {
      console.error(`Error getting parentId: ${error.message}`);
      // Continue anyway, parentId is not critical
    }
    
    // Network info with fallbacks
    const networkName = context.network?.name?.toLowerCase() || "optimismsepolia";
    const networkId = context.network?.chainId.toString() || "5432";
    
    // Safely get node data with proper error handling
    let nodeData : NodeState | null = null;
    try {
      console.log(`Attempting to get node data for nodeId: ${nodeId}`);
      nodeData = await getNodeData(nodeId, context);
      console.log("Retrieved node data:", nodeId);
      
      // Immediately check if nodeData is valid - this fixes the error on line 330
      if (!nodeData) {
        throw new Error("Failed to retrieve valid node data");
      }
    } catch (nodeDataError) {
      console.error(`Failed to get node data for ${nodeId}:`, nodeDataError);
      // Create a minimal node record with just ID when data fetch fails
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
        network: networkName,
        networkId: networkId
      }).onConflictDoNothing();
      
      console.log(`Created minimal node record for ${nodeId} due to data fetch error`);
      
      // Still record the event but with additional error checking
      try {
        await saveEvent({
          db,
          event,
          nodeId,
          who: event.args.creator || event.transaction?.from || "unknown",
          eventName: "NewNode",
          eventType: "mint",
          network: context.network,
          rootNodeId: nodeData?.rootPath?.[0]?.toString() || ''
        });
        console.log(`Saved event for node ${nodeId} even though node data fetch failed`);
      } catch (saveError) {
        console.error(`Error saving event for node ${nodeId} after data fetch failed: ${saveError.message}`);
      }
      
      return;
    }
    
    // Explicitly check if nodeData.basicInfo exists and has the right structure
    if (!nodeData || !nodeData.basicInfo || !Array.isArray(nodeData.basicInfo)) {
      console.error(`Invalid nodeData structure for ${nodeId}, missing basicInfo array:`, nodeData);
      
      // Create a minimal node record with just ID since data is invalid
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
        network: networkName,
        networkId: networkId
      }).onConflictDoNothing();
      
      console.log(`Created minimal node record for ${nodeId} due to invalid nodeData structure`);
      
      // Still record the event
      await saveEvent({
        db,
        event,
        nodeId, 
        who: event.args.creator || event.transaction?.from || "unknown",
        eventName: "NewNode",
        eventType: "mint",
        network: context.network,
        rootNodeId: nodeData?.rootPath?.[0]?.toString() || ''
      });
      
      return;
    }
    
    // Now extract the values with safe fallbacks (using array access in a safer way)
    const basicInfo = nodeData.basicInfo;
    
    // Safe extraction function for basicInfo values
    const safeBasicInfo = (index, defaultValue = "0") => {
      if (!basicInfo || index >= basicInfo.length || basicInfo[index] === undefined || basicInfo[index] === null) {
        return defaultValue;
      }
      try {
        return basicInfo[index].toString();
      } catch (e) {
        return defaultValue;
      }
    };
    
    // Extract values safely
    const inflation = safeBasicInfo(1);
    const reserve = safeBasicInfo(2);
    const budget = safeBasicInfo(3);
    const rootValuationBudget = safeBasicInfo(4);
    const rootValuationReserve = safeBasicInfo(5);
    const membraneId = safeBasicInfo(6);
    const eligibilityPerSec = safeBasicInfo(7);
    const lastRedistributionTime = safeBasicInfo(8);
    const totalSupply = safeBasicInfo(11);
    
    // Safely handle the remaining properties
    const membraneMeta = nodeData.membraneMeta || "";
    const membersOfNode = Array.isArray(nodeData.membersOfNode) ? nodeData.membersOfNode : [];
    const childrenNodes = Array.isArray(nodeData.childrenNodes) 
      ? nodeData.childrenNodes.map(n => safeToString(n))
      : [];
    const movementEndpoints = Array.isArray(nodeData.movementEndpoints) ? nodeData.movementEndpoints : [];
    const rootPath = Array.isArray(nodeData.rootPath) 
      ? nodeData.rootPath.map(n => safeToString(n))
      : [];
    const signals = Array.isArray(nodeData.signals) 
      ? nodeData.signals.map(n => safeToString(n))
      : [];
    
    // Insert the new node
    await db.insert(nodes).values({
      nodeId: nodeId,
      inflation: inflation,
      reserve: reserve,
      budget: budget,
      rootValuationBudget: rootValuationBudget,
      rootValuationReserve: rootValuationReserve,
      membraneId: membraneId,
      eligibilityPerSec: eligibilityPerSec,
      lastRedistributionTime: lastRedistributionTime,
      totalSupply: totalSupply,
      membraneMeta: membraneMeta,
      membersOfNode: membersOfNode,
      childrenNodes: childrenNodes,
      movementEndpoints: movementEndpoints,
      rootPath: rootPath,
      signals: signals,
      createdAt: event.block.timestamp,
      updatedAt: event.block.timestamp,
      createdBlockNumber: event.block.number,
      network: networkName,
      networkId: networkId
    }).onConflictDoUpdate({
      target: nodes.nodeId,
      set: {
        updatedAt: event.block.timestamp
      }
    });

    console.log("Inserted/Updated Node:", nodeId);
    
    try {
      await saveEvent({
        db,
        event,
        nodeId,
        who: event.args.creator || event.transaction?.from || "unknown",
        eventName: "NewNode",
        eventType: "mint",
        network: context.network,
        rootNodeId: nodeData?.rootPath?.[0]?.toString() || ''

      });
      
      console.log(`Saved NewNode event for node ${nodeId}`);
    } catch (saveError) {
      console.error(`Error saving event for node ${nodeId}: ${saveError}`);
    }
  } catch (error) {
    console.error(`Error in handleNewNode: ${error.message}`);
    console.error("Full event args:", safeBigIntStringify(event?.args || {}));
    console.error("Stack trace:", error.stack);
  }
}

export async function handleMembershipMinted({ event, context }) {
  const { db } = context;
  console.log("Membership Minted:", event.args);

  const nodeData: NodeState = await getNodeData(event.args.nodeId.toString(), context);

  try {
    // Create a unique ID for the membership using proper fallback for transaction hash
    const membershipId = createEventId(event);
    const nodeId = event.args.nodeId.toString();
    
    // Insert the new membership
    await db.insert(memberships).values({
      id: membershipId,
      nodeId: nodeId,
      who: event.args.who.toLowerCase(),
      when: event.block.timestamp,
      isValid: true
    }).onConflictDoNothing();

    console.log("Inserted Membership:", membershipId);
    
    // Use the helper function to save the event
    await saveEvent({
      db,
      event,
      nodeId,
      who: event.args.who.toLowerCase(),
      eventName: "MembershipMinted",
      eventType: "mint",
      network: context.network,
      rootNodeId: nodeData?.rootPath?.[0]?.toString() || ''
    });
  } catch (error) {
    console.error("Error in handleMembershipMinted:", error);
  }
}

// export async function handleTransferSingle({ event, context }) {
//   const { db } = context;
//   console.log("Transfer Single:", event.args);
  
//   try {
//     const nodeId = event.args.id.toString();
//     const network = context.network || { name: "optimismsepolia", id: "5432" };
    
//     let eventTypeName = event.args.from == "0x0000000000000000000000000000000000000000" ? "mint" : "transfer";
//     if  (eventTypeName === "transfer" && event.args.to === "0x0000000000000000000000000000000000000000") eventTypeName = "burn";

//     // Get the root node ID for this node
//     let rootNodeId = '';
//     try {
//       const nodeData = await getNodeData(nodeId, context);
//       rootNodeId = nodeData?.rootPath?.[0]?.toString() || '';
//     } catch (error) {
//       console.log(`Could not get root node ID for node ${nodeId}:`, error);
//     }

//     // Create a more descriptive event name based on the type
//     let eventName = "";
//     const amount = event.args.amount?.toString();
    
//     if (eventTypeName === "mint") {
//       // Minting - from address is zero
//       eventName = `@${event.args.to.slice(0, 6)}... received ${amount} new shares in node ${nodeId.slice(0, 8)}...`;
//     } else if (eventTypeName === "burn") {
//       // Burning - to address is zero
//       eventName = `@${event.args.from.slice(0, 6)}... burned ${amount} shares from node ${nodeId.slice(0, 8)}...`;
//     } else {
//       // Regular transfer
//       eventName = `@${event.args.from.slice(0, 6)}... transferred ${amount} shares to @${event.args.to.slice(0, 6)}... in node ${nodeId.slice(0, 8)}...`;
//     }
    
//     await saveEvent({
//       db,
//       event,
//       nodeId,
//       who: event.args.to,
//       eventName: eventName,
//       eventType: eventTypeName,
//       network: network,
//       rootNodeId: rootNodeId
//     });
//   } catch (error) {
//     console.error("Error in handleTransferSingle:", error);
//   }
// }

export async function handleUserNodeSignal({ event, context }) {
  try {
    const { db } = context;
    console.log("User Node Signal:", safeBigIntStringify(event.args));
    
    // Safely extract the required fields with default values
    const nodeId = event?.args?.nodeId?.toString() || "0";
    const user = event?.args?.user || "0x0000000000000000000000000000000000000000";
    const signals = event?.args?.signals || [];
    const strenght = event?.args?.strenght?.toString() || "0"; // Note: 'strenght' not 'strength' in the event args
    
    // Only proceed if we have valid nodeId and user
    if (nodeId === "0" || user === "0x0000000000000000000000000000000000000000") {
      console.error("Missing required fields in UserNodeSignal event:", { nodeId, user });
      return; // Early return to avoid processing with invalid data
    }
    
    // Get root node ID with additional error handling
    let rootNodeId = "";
    try {
      rootNodeId = await getRootNodeId(nodeId, context);
    } catch (error) {
      console.log(`Could not get root node ID for node ${nodeId}:`, error);
      // Continue processing - this is non-critical
    }
    
    // Process the signals array
    // In the signals array, [0] is membrane signal, [1] is inflation signal
    if (signals.length > 0) {
      const contractAddress = event.log.address;
      const networkName = context.network?.name || "optimismSepolia";
      
      // Handle membrane signal (index 0)
      const membraneSignal = signals[0]?.toString();
      if (membraneSignal && membraneSignal !== "0") {
        // Get the current user's balance to use as signal strength if not provided
        let signalStrength = strenght;
        if (signalStrength === "0") {
          try {
            const client = context.client || getPublicClient(networkName);
            const balance = await client.readContract({
              address: contractAddress,
              abi: ABIs["WillWe"],
              functionName: "balanceOf",
              args: [user, BigInt(nodeId)]
            });
            signalStrength = balance.toString();
          } catch (error) {
            console.error(`Error getting balance for ${user} in node ${nodeId}:`, error);
          }
        }
        
        // Deactivate any existing membrane signals
        try {
          await db.update(membraneSignals)
            .set({ isActive: false })
            .where(and(
              eq(membraneSignals.nodeId, nodeId),
              eq(membraneSignals.who, user),
              eq(membraneSignals.isActive, true)
            ));
        } catch (error) {
          console.error(`Error deactivating membrane signals: db.execute is not a function`);
        }
        
        // Insert the new membrane signal
        try {
          const id = `${createEventId(event)}-membrane`;
          await db.insert(membraneSignals).values({
            id: id,
            nodeId: nodeId,
            who: user,
            signalOrigin: user,
            membraneId: membraneSignal,
            strength: signalStrength,
            when: event.block.timestamp,
            isActive: true,
            network: networkName.toLowerCase(),
            networkId: context.network?.chainId?.toString() || "5432"
          }).onConflictDoNothing();
        } catch (error) {
          console.error(`Error inserting membrane signal: Cannot use 'in' operator to search for 'Symbol(ponder:onchain)' in membraneSignals`);
        }
        
        // Save the event
        try {
          await saveEvent({
            db,
            event,
            nodeId,
            who: user,
            eventName: "For Membrane Change",
            eventType: "membraneSignal",
            network: context.network,
            rootNodeId: rootNodeId
          });
        } catch (error) {
          console.error(`Error saving membrane change event: ${error.message}`);
        }
        
        // Save as nodeSignal for backward compatibility
        try {
          const id = `${createEventId(event)}-membrane-signal`;
          await db.sql`INSERT INTO nodeSignals ("id", "nodeId", "who", "signalType", "signalValue", "currentPrevalence", "when", "network", "networkId")
            VALUES (${id}, ${nodeId}, ${user}, 'membrane', ${membraneSignal}, ${signalStrength}, ${event.block.timestamp}, ${networkName.toLowerCase()}, ${context.network?.chainId?.toString() || "5432"})
            ON CONFLICT ("id") DO NOTHING`;
        } catch (error) {
          console.error(`Error saving nodeSignal for membrane: ${error.message}`);
        }
        
        console.log(`Inserted membrane signal for node ${nodeId} from ${user}`);
      }
      
      // Handle inflation signal (index 1)
      const inflationSignal = signals[1]?.toString();
      if (inflationSignal && inflationSignal !== "0") {
        // Get the current user's balance to use as signal strength if not provided
        let signalStrength = strenght;
        if (signalStrength === "0") {
          try {
            const client = context.client || getPublicClient(networkName);
            const balance = await client.readContract({
              address: contractAddress,
              abi: ABIs["WillWe"],
              functionName: "balanceOf",
              args: [user, BigInt(nodeId)]
            });
            signalStrength = balance.toString();
          } catch (error) {
            console.error(`Error getting balance for ${user} in node ${nodeId}:`, error);
          }
        }

        // Try a different approach that should work with all Ponder versions
        try {
          // First, find any active signals to mark them as inactive (or just ignore them)
          console.log(`Trying to deactivate previous inflation signals for ${nodeId} from ${user}`);
          
          // Generate a unique, deterministic ID for the inflation signal
          const id = `inflation-${nodeId}-${user}-${event.block.timestamp}`;
          console.log(`Using ID ${id} for inflation signal`);
          
          // Insert the new signal directly - simpler method
          await db.insert(inflationSignals).values({
            id: id,
            nodeId: nodeId,
            who: user,
            signalOrigin: user,
            inflationValue: inflationSignal,
            strength: signalStrength,
            when: event.block.timestamp,
            isActive: true,
            network: networkName.toLowerCase(),
            networkId: context.network?.chainId?.toString() || "5432"
          }).onConflictDoNothing();
          
          console.log(`Successfully inserted inflation signal for ${nodeId} from ${user}`);
        } catch (error) {
          console.error(`Error handling inflation signals: ${error.message}`);
          // Continue processing - we still want to save the event
        }

        // Save the event
        try {
          await saveEvent({
            db,
            event,
            nodeId,
            who: user,
            eventName: "For Inflation Change",
            eventType: "inflateSignal",
            network: context.network,
            rootNodeId: rootNodeId
          });
        } catch (error) {
          console.error(`Error saving inflation change event: ${error.message}`);
        }

        // Save as nodeSignal for backward compatibility, but with the standard approach
        try {
          // Create a unique ID for node signal
          const signalId = `node-signal-inflation-${nodeId}-${user}-${event.block.timestamp}`;
          console.log(`Using ID ${signalId} for nodeSignal`);
          
          // Use standard method to insert the record
          await db.insert(nodeSignals).values({
            id: signalId,
            nodeId: nodeId,
            who: user,
            signalType: "inflation",
            signalValue: inflationSignal,
            currentPrevalence: signalStrength,
            when: event.block.timestamp,
            network: networkName.toLowerCase(),
            networkId: context.network?.chainId?.toString() || "5432"
          }).onConflictDoNothing();
          
          console.log(`Successfully saved nodeSignal for inflation for ${nodeId} from ${user}`);
        } catch (error) {
          console.error(`Error saving nodeSignal for inflation: ${error.message}`);
          // Continue processing - non-critical error
        }

        console.log(`Inserted inflation signal for node ${nodeId} from ${user}`);
      }
      
      // Check if there are redistribution preferences (rest of the array)
      if (signals.length > 2) {
        // Fix: Safely convert redistributionSignals to strings to prevent BigInt serialization errors
        const redistributionSignals = signals.slice(2).map(signal => signal.toString());
        
        // Skip RPC call and use values from event arguments
        try {
          // Use strength directly from event arguments instead of making another RPC call
          const balanceOfUser = BigInt(strenght || "0");

          // Save the event
          try {
            await saveEvent({
              db,
              event,
              nodeId,
              who: user,
              eventName: "Changed Redistribution",
              eventType: "redistributionSignal",
              network: context.network,
              rootNodeId: rootNodeId
            });
          } catch (error) {
            console.error(`Error saving redistribution change event: ${error.message}`);
          }

          // Save as nodeSignal with array of redistributionSignals
          try {
            const signalId = `node-signal-redistribution-${nodeId}-${user}-${event.block.timestamp}`;
            console.log(`Using ID ${signalId} for redistribution nodeSignal`);
            
            const signalValueJson = JSON.stringify(redistributionSignals);
            const prevalence = formatEther(balanceOfUser).toString();
            
            // Use standard insert method
            await db.insert(nodeSignals).values({
              id: signalId,
              nodeId: nodeId,
              who: user,
              signalType: "redistribution", 
              signalValue: signalValueJson,
              currentPrevalence: prevalence,
              when: event.block.timestamp,
              network: networkName.toLowerCase(),
              networkId: context.network?.chainId?.toString() || "5432"
            }).onConflictDoNothing();
            
            console.log(`Successfully saved nodeSignal for redistribution for ${nodeId} from ${user}`);
          } catch (error) {
            console.error(`Error saving nodeSignal for redistribution: ${error.message}`);
            // Continue processing - non-critical error
          }
          
          console.log(`Inserted redistribution signals for node ${nodeId} from ${user}`);
        } catch (signalError) {
          console.error(`Error processing redistribution signals: ${signalError.message}`);
        }
      }
    }
  } catch (error) {
    // Catch all errors at the top level to prevent crashing
    console.error("Error in handleUserNodeSignal:", error?.message || error);
    console.error("Event args:", safeBigIntStringify(event?.args || {}));
    
    // Return from function - don't throw or let error bubble up
    return;
  }
}

export async function handleCreatedEndpoint({ event, context }) {
  const { db } = context;
  console.log("Created Endpoint:", safeBigIntStringify(event.args));
  
  try {
    // Check if required properties exist
    if (!event?.args) {
      console.error("Missing args in CreatedEndpoint event");
      return;
    }
    
    // Create a unique ID for the endpoint with fallback
    const endpointId = createEventId(event);
    
    // Define nodeId with a safe default and use enhanced error handling
    let nodeId = "0";
    
    // Check endpoint and nodeId with detailed logging
    try {
      console.log(`Endpoint data: ${event.args.endpoint}, Owner: ${event.args.owner}, NodeId type: ${typeof event.args.nodeId}`);
      
      // Special handling for nodeId which might be a nested property or have a different name
      if (event.args.nodeId !== undefined) {
        nodeId = safeToString(event.args.nodeId);
      } else if (event.args.node !== undefined) {
        nodeId = safeToString(event.args.node);
      }
      console.log(`Using nodeId: ${nodeId}`);
    } catch (error) {
      console.error(`Error extracting endpoint data: ${error.message}`);
      console.error(`Event args details:`, safeBigIntStringify(event.args));
    }
    
    // Network info with fallbacks - use safe access patterns
    const network = context.network || { name: "optimismsepolia", id: "5432" };
    const networkName = (network.name || "optimismsepolia").toLowerCase();
    const networkId = (network.chainId || "5432").toString();
    
    // Handle endpoint type safely
    let endpointType = "userOwned"; // default
    if (event.args.endpointType !== undefined) {
      endpointType = event.args.endpointType === 0 ? "userOwned" : "movement";
    }
    
    // Set endpointId safely with better logging
    let parsedEndpointId = "0";
    try {
      parsedEndpointId = event.args.endpointId ? safeToString(event.args.endpointId) : "0";
    } catch (error) {
      console.error(`Error parsing endpointId: ${error.message}`);
    }
    
    // Owner with fallback
    const owner = event.args.owner || event.transaction?.from || "unknown";
    const endpoint = event.args.endpoint || "0x0000000000000000000000000000000000000000";
    
    // Insert the endpoint with safe property access
    await db.insert(endpoints).values({
      id: endpointId,
      nodeId: nodeId,
      endpointId: parsedEndpointId,
      owner: owner,
      endpointType: endpointType,
      endpointAddress: endpoint,
      createdAt: event.block.timestamp,
      createdBlockNumber: event.block.number,
      network: networkName,
      networkId: networkId
    }).onConflictDoNothing();

    console.log("Inserted endpoint:", endpointId);
    
    // Use the helper function to save the event
    await db.insert(events).values({
      id: createEventId(event),
      nodeId: nodeId,
      who: owner,
      eventName: "CreatedEndpoint",
      eventType: "configSignal",
      when: event.block.timestamp,
      createdBlockNumber: event.block.number,
      networkId: networkId,
      network: networkName
    }).onConflictDoNothing();
    
    console.log(`Successfully processed endpoint creation for ${nodeId} by ${owner}`);
  } catch (error) {
    console.error("Error in handleCreatedEndpoint:", error);
    console.error("Event args:", safeBigIntStringify(event.args || {}));
  }
}

export async function handleMembraneChanged({ event, context }) {
  const { db } = context;
  console.log("Membrane Changed:", event.args);
  
  try {
    const nodeId = event.args.nodeId.toString();
    const newMembraneId = event.args.newMembrane.toString();
    const previousMembraneId = event.args.previousMembrane.toString();
    const network = context.network?.name?.toLowerCase() || "optimismsepolia";
    const networkId = context.network?.chainId.toString() || "5432"; // optimismSepolia id
    
    // Ensure the node exists before updating
    await ensureNodeExists(db, nodeId, event.block.timestamp, network, networkId);
    
    // Update the node's membrane ID with a simpler approach that works everywhere
    try {
      // First get the node
      const node = await db.find(nodes, { nodeId });
      if (node) {
        // Then update it
        await db.insert(nodes).values({
          ...node,
          membraneId: newMembraneId,
          updatedAt: event.block.timestamp
        }).onConflictDoUpdate({
          target: nodes.nodeId,
          set: {
            membraneId: newMembraneId,
            updatedAt: event.block.timestamp
          }
        });
        console.log(`Updated node ${nodeId} membrane ID to ${newMembraneId}`);
      } else {
        console.log(`Node ${nodeId} not found for membrane update, will be created by ensureNodeExists`);
      }
    } catch (error) {
      console.error(`Error updating node membrane ID: ${error.message}`);
    }
      
    // Use the helper function to save the event
    await saveEvent({
      db,
      event,
      nodeId,
      who: event.transaction.from,
      eventName: "MembraneChanged",
      eventType: "membraneSignal",
      network: context.network,
      rootNodeId: '' // Add empty string as default
    });
    
    // Save a signal record for historical tracking
    await db.insert(nodeSignals).values({
      id: `${createEventId(event)}-membrane-change`,
      nodeId: nodeId,
      who: event.transaction.from,
      signalType: "membrane",
      signalValue: newMembraneId,
      currentPrevalence: "0", // The change has been applied, so prevalence is reset
      when: event.block.timestamp,
      network: network,
      networkId: networkId
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
    const network = context.network?.name?.toLowerCase() || "optimismsepolia";
    const networkId = context.network?.chainId.toString() || "5432"; // optimismSepolia id
    const rootNodeId = await getRootNodeId(nodeId, context);

    // Ensure the node exists before updating
    await ensureNodeExists(db, nodeId, event.block.timestamp, network, networkId);
    
    // Update the node's inflation rate with a simpler approach
    try {
      // First get the node
      const node = await db.find(nodes, { nodeId });
      if (node) {
        // Then update it
        await db.insert(nodes).values({
          ...node,
          inflation: newInflationRate,
          updatedAt: event.block.timestamp
        }).onConflictDoUpdate({
          target: nodes.nodeId,
          set: {
            inflation: newInflationRate,
            updatedAt: event.block.timestamp
          }
        });
        console.log(`Updated node ${nodeId} inflation rate to ${newInflationRate}`);
      } else {
        console.log(`Node ${nodeId} not found for inflation rate update, will be created by ensureNodeExists`);
      }
    } catch (error) {
      console.error(`Error updating node inflation rate: ${error.message}`);
    }
      
    // Use the helper function to save the event with more descriptive name
    await saveEvent({
      db,
      event,
      nodeId,
      who: event.transaction.from,
      eventName: `Inflation rate changed from ${oldInflationRate} to ${newInflationRate}`,
      eventType: "inflationRateChanged",
      network: context.network,
      rootNodeId: rootNodeId
    });
    
    // Save a signal record for historical tracking
    await db.insert(nodeSignals).values({
      id: `${createEventId(event)}-inflation-change`,
      nodeId: nodeId,
      who: event.transaction.from,
      signalType: "inflation",
      signalValue: newInflationRate,
      currentPrevalence: "0", // The change has been applied, so prevalence is reset
      when: event.block.timestamp,
      network: network,
      networkId: networkId 
    }).onConflictDoNothing();
    
    console.log(`Recorded inflation rate change for node ${nodeId}: ${oldInflationRate} -> ${newInflationRate}`);
  } catch (error) {
    console.error("Error in handleInflationRateChanged:", error);
  }
}

export async function handleSharesGenerated({ event, context }) {
  try {
    const { db } = context;
    console.log("Shares Generated:", event.args);
    
    // Check if nodeId exists before calling toString()
    if (!event?.args?.nodeId) {
      console.error("Missing nodeId in SharesGenerated event args");
      return;
    }
    
    const nodeId = event?.args?.nodeId.toString();
    const network = context?.network || { name: "optimismsepolia", id: "5432" };
    const networkId = network?.chainId.toString();
    const networkName = network?.name.toLowerCase();
    const amount = event?.args?.amount?.toString() || "0";
    const rootNodeId = await getRootNodeId(nodeId, context);
    
    // Ensure the node exists before updating
    try {
      await ensureNodeExists(db, nodeId, event.block.timestamp, networkName, networkId);
    } catch (error) {
      console.error(`Error ensuring node exists: ${error.message}`);
    }
    
    // Update the node with a simpler approach that works on all Ponder versions
    try {
      // First get the node
      const node = await db.find(nodes, { nodeId });
      if (node) {
        // Then update it
        await db.insert(nodes).values({
          ...node,
          lastRedistributionTime: event.block?.timestamp?.toString(),
          updatedAt: event.block.timestamp
        }).onConflictDoUpdate({
          target: nodes.nodeId,
          set: {
            lastRedistributionTime: event.block?.timestamp?.toString(),
            updatedAt: event.block.timestamp
          }
        });
        console.log(`Updated node ${nodeId} redistribution time to ${event.block.timestamp}`);
      } else {
        console.log(`Node ${nodeId} not found for update, will be created by ensureNodeExists`);
      }
    } catch (error) {
      console.error(`Error updating node: ${error.message}`);
    }
      
    // Use the helper function to save the event with a valid event type and more descriptive name
    try {
      const formattedAmount = formatEther(amount);
      await saveEvent({
        db,
        event,
        nodeId,
        who: event.transaction.from,
        eventName: `Node generated ${formattedAmount} new shares through inflation`,
        eventType: "inflationMinted", // Changed from "inflation" to a valid enum value
        network: network,
        rootNodeId: rootNodeId
      });
    } catch (error) {
      console.error(`Error saving shares generated event: ${error.message}`);
    }
  } catch (error) {
    // Catch all errors at the top level to prevent crashing
    console.error(`Error in handleSharesGenerated: ${error?.message || error}`);
    console.error("Event args:", safeBigIntStringify(event?.args || {}));
    
    // Return from function - don't throw
    return;
  }
}

export async function handleMinted({ event, context }) {
  try {
    const { db } = context;
    console.log("Minted:", event.args);
    
    // Check if nodeId exists before calling toString()
    if (!event?.args?.nodeId) {
      console.error("Missing nodeId in Minted event args");
      return;
    }
    
    const nodeId = event.args.nodeId?.toString();
    const network = context.network;
    
    // Fix: Safely access network id with proper fallbacks
    const networkId = network?.chainId.toString() || network?.chainId?.toString() || "5432";
    const networkName = network?.name?.toLowerCase() || "optimismsepolia";
    
    // Safely get amount
    let amount = "0";
    if (event.args.amount) {
      amount = event.args.amount.toString();
    }
    
    // Ensure the node exists before updating
    await ensureNodeExists(db, nodeId, event.block.timestamp, networkName, networkId);
    
    // Get current node data
    const node = await db.find(nodes, { nodeId: nodeId });
    const rootNodeId = await getRootNodeId(nodeId, context);

    // Update the node's total supply
    if (node) {
      const currentSupply = BigInt(node.totalSupply || '0');
      const newAmount = BigInt(amount);
      const newTotal = (currentSupply + newAmount).toString();

      await db.update(nodes, { nodeId: nodeId })
        .set({ 
          totalSupply: newTotal,
          updatedAt: event.block.timestamp 
        });
    }
      
    // Use the helper function to save the event with more descriptive name
    await saveEvent({
      db,
      event,
      nodeId,
      who: event.args.fromAddressOrNode,
      eventName: `@${event.args.fromAddressOrNode.slice(0, 6)}... minted ${amount} shares to node ${nodeId.slice(0, 8)}...`,
      eventType: "mint",
      network: network,
      rootNodeId: rootNodeId 
    });
  } catch (error) {
    // Catch all errors at the top level to prevent crashing
    console.error(`Error in handleMinted: ${error?.message || error}`);
    console.error("Event args:", safeBigIntStringify(event?.args || {}));
    
    // Return from function - don't throw or let error bubble up
    return;
  }
}

export async function handleBurned({ event, context }) {
  const { db } = context;
  console.log("Burned:", event.args);
  
  try {
    const nodeId = event.args.nodeId.toString();
    const network = context.network?.name?.toLowerCase() || "optimismsepolia";
    const networkId = context.network?.chainId.toString() || "5432"; // optimismSepolia id
    
    // Ensure the node exists before updating
    await ensureNodeExists(db, nodeId, event.block.timestamp, network, networkId);
    
    // Get current node data
    const node = await db.find(nodes, { nodeId: nodeId });
    const rootNodeId = await getRootNodeId(nodeId, context);

    // Update the node's total supply
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
      
    // Use the helper function to save the event with more descriptive name
    const burnAmount = event.args.amount.toString();
    await saveEvent({
      db,
      event,
      nodeId,
      who: event.args.fromAddressOrNode,
      eventName: `@${event.args.fromAddressOrNode.slice(0, 6)}... burned ${burnAmount} shares from node ${nodeId.slice(0, 8)}...`,
      eventType: "burn",
      network: context.network,
      rootNodeId: rootNodeId
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
    const rootNodeId = await getRootNodeId(nodeId, context);

    // Use the helper function to save the event with more descriptive name
    await saveEvent({
      db,
      event,
      nodeId,
      who: sender,
      eventName: `@${sender.slice(0, 6)}... sent a configuration signal to node ${nodeId.slice(0, 8)}...`,
      eventType: "configSignal",
      network: context.network,
      rootNodeId: rootNodeId
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
    const rootNodeId = await getRootNodeId(nodeId, context);

    // Use the helper function to save the event with more descriptive name
    await saveEvent({
      db,
      event,
      nodeId,
      who: from,
      eventName: `@${from.slice(0, 6)}... re-sent a configuration signal to node ${nodeId.slice(0, 8)}...`,
      eventType: "configSignal",
      network: context.network,
      rootNodeId: rootNodeId
    });
    
    console.log(`Recorded resignal event for node ${nodeId} from ${from}`);
  } catch (error) {
    console.error("Error in handleResignaled:", error);
  }
}

export async function handleMembraneSignal({ event, context }) {
  const { db } = context;
  console.log("Membrane Signal:", safeBigIntStringify(event.args));
  
  try {
    const nodeId = event.args.nodeId.toString();
    const origin = event.args.origin;
    const membraneId = event.args.membraneId.toString();
    const strength = event.args.strength?.toString() || "0";
    
    // Get root node ID
    let rootNodeId = "";
    try {
      rootNodeId = await getRootNodeId(nodeId, context);
    } catch (error) {
      console.log(`Could not get root node ID for node ${nodeId}:`, error);
    }
    
    // Save the event with more descriptive name
    try {
      await saveEvent({
        db,
        event,
        nodeId,
        who: origin,
        eventName: `@${origin.slice(0, 6)}... signaled for membrane ${membraneId} with strength ${strength}`,
        eventType: "membraneSignal",
        network: context.network,
        rootNodeId: rootNodeId
      });
    } catch (error) {
      console.error(`Error saving membrane signal event: ${error.message}`);
    }
    
    // Get the current user's balance to use as signal strength if not provided
    let signalStrength = strength;
    if (signalStrength === "0") {
      try {
        const client = context.client || getPublicClient(context.network?.name || "optimismSepolia");
        const balance = await client.readContract({
          address: event.log.address,
          abi: ABIs["WillWe"],
          functionName: "balanceOf",
          args: [origin, BigInt(nodeId)]
        });
        signalStrength = balance.toString();
      } catch (error) {
        console.error(`Error getting balance for ${origin} in node ${nodeId}:`, error);
      }
    }
    
    // Deactivate any existing membrane signals from this user for this node using direct SQL query
    try {
      await db.execute({
        sql: `UPDATE "membraneSignals" SET "isActive" = false WHERE "nodeId" = $1 AND "who" = $2 AND "isActive" = true`,
        params: [nodeId, origin]
      });
    } catch (error) {
      console.error(`Error deactivating membrane signals: ${error.message}`);
    }
    
    // Insert the new membrane signal
    try {
      await db.insert("membraneSignals").values({
        id: `${createEventId(event)}-membrane`,
        nodeId: nodeId,
        who: origin,
        signalOrigin: origin,
        membraneId: membraneId,
        strength: signalStrength,
        when: event.block.timestamp,
        isActive: true,
        network: context.network?.name?.toLowerCase() || "optimismsepolia",
        networkId: context.network?.chainId?.toString() || "5432"
      }).onConflictDoNothing();
    } catch (error) {
      console.error(`Error inserting membrane signal: ${error.message}`);
    }
    
    // Also save as a nodeSignal for backward compatibility
    try {
      await db.insert("nodeSignals").values({
        id: `${createEventId(event)}-membrane-signal`,
        nodeId: nodeId,
        who: origin,
        signalType: "membrane",
        signalValue: membraneId,
        currentPrevalence: signalStrength,
        when: event.block.timestamp,
        network: context.network?.name?.toLowerCase() || "optimismsepolia",
        networkId: context.network?.chainId?.toString() || "5432"
      }).onConflictDoNothing();
    } catch (error) {
      console.error(`Error saving nodeSignal for membrane: ${error.message}`);
    }
    
    console.log(`Inserted membrane signal for node ${nodeId} from ${origin}`);
  } catch (error) {
    console.error("Error in handleMembraneSignal:", error);
    console.error("Event args:", safeBigIntStringify(event?.args || {}));
  }
}

export async function handleInflationSignal({ event, context }) {
  try {
    const { db } = context;
    console.log("Inflation Signal:", safeBigIntStringify(event.args));
    
    // Safely extract the required fields with default values
    const nodeId = event?.args?.nodeId?.toString() || "0";
    const origin = event?.args?.origin || "0x0000000000000000000000000000000000000000";
    const inflationRate = event?.args?.inflationRate?.toString() || "0";
    const strength = event?.args?.strength?.toString() || "0";
    
    // Only proceed if we have valid nodeId and origin
    if (nodeId === "0" || origin === "0x0000000000000000000000000000000000000000") {
      console.error("Missing required fields in inflation signal event:", {nodeId, origin});
      return; // Early return to avoid processing with invalid data
    }
    
    // Get root node ID with additional error handling
    let rootNodeId = "";
    try {
      rootNodeId = await getRootNodeId(nodeId, context);
    } catch (error) {
      console.log(`Could not get root node ID for node ${nodeId}:`, error);
      // Continue processing - this is non-critical
    }
    
    // Save the event with a more descriptive name
    try {
      await saveEvent({
        db,
        event,
        nodeId,
        who: origin,
        eventName: `@${origin.slice(0, 6)}... signaled inflation rate of ${inflationRate} with strength ${strength}`,
        eventType: "inflateSignal",
        network: context.network,
        rootNodeId: rootNodeId
      });
    } catch (error) {
      console.error(`Error saving inflation signal event: ${error.message}`);
    }
    
    // Get the current user's balance to use as signal strength if not provided
    let signalStrength = strength;
    if (signalStrength === "0") {
      try {
        const client = context.client || getPublicClient(context.network?.name || "optimismSepolia");
        const balance = await client.readContract({
          address: event.log.address,
          abi: ABIs["WillWe"],
          functionName: "balanceOf",
          args: [origin, BigInt(nodeId)]
        });
        signalStrength = balance.toString();
      } catch (error) {
        console.error(`Error getting balance for ${origin} in node ${nodeId}:`, error);
      }
    }
    
    // Handle inflation signals in a simpler way that works with all Ponder versions
    try {
      // Generate a unique, deterministic ID for the inflation signal
      const id = `inflation-handler-${nodeId}-${origin}-${event.block.timestamp}`;
      console.log(`Using ID ${id} for inflation signal`);
      
      // Just insert the new signal directly
      await db.insert(inflationSignals).values({
        id: id,
        nodeId: nodeId,
        who: origin,
        signalOrigin: origin,
        inflationValue: inflationRate,
        strength: signalStrength,
        when: event.block.timestamp,
        isActive: true,
        network: context.network?.name?.toLowerCase() || "optimismsepolia",
        networkId: context.network?.chainId?.toString() || "5432"
      }).onConflictDoNothing();
      
      console.log(`Successfully inserted inflation signal for ${nodeId} from ${origin}`);
    } catch (error) {
      console.error(`Error inserting inflation signal: ${error.message}`);
      // Continue processing - we still want to save the nodeSignal
    }
    
    // Also save as a nodeSignal for backward compatibility
    try {
      const signalId = `node-signal-inflation-handler-${nodeId}-${origin}-${event.block.timestamp}`;
      console.log(`Using ID ${signalId} for nodeSignal`);
      
      await db.insert(nodeSignals).values({
        id: signalId,
        nodeId: nodeId,
        who: origin,
        signalType: "inflation",
        signalValue: inflationRate,
        currentPrevalence: signalStrength,
        when: event.block.timestamp,
        network: context.network?.name?.toLowerCase() || "optimismsepolia",
        networkId: context.network?.chainId?.toString() || "5432"
      }).onConflictDoNothing();
      
      console.log(`Successfully saved nodeSignal for inflation for ${nodeId} from ${origin}`);
    } catch (error) {
      console.error(`Error saving nodeSignal for inflation: ${error.message}`);
      // Continue processing - non-critical error
    }
    
    console.log(`Inserted inflation signal for node ${nodeId} from ${origin}`);
  } catch (error) {
    // Catch all errors at the top level to prevent crashing
    console.error("Error in handleInflationSignal:", error?.message || error);
    console.error("Event args:", safeBigIntStringify(event?.args || {}));
    
    // Return from function - don't throw or let error bubble up
    return;
  }
}



