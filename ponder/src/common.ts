/**
 * Common utility functions shared across handlers
 */
import { events } from "../ponder.schema";
import { deployments, ABIs } from "../abis/abi";
import { supportedChains } from "../ponder.config";
import { NodeState, AllNodeSignals } from "./types";
import { http, createPublicClient } from "viem";
/**
 * Creates a unique ID from an event
 */
export const createEventId = (event) => {
  if (!event) return `unknown-${Date.now()}`;
  
  const transactionHash = event.transaction?.hash || 
                         `tx-${event.block?.hash || 'unknown'}-${event.block?.number || 0}`;
  const logIndex = event.log?.logIndex || 0;
  
  return `${transactionHash}-${logIndex}`;
};


/**
 * Safely inserts an event with proper error handling
 */
export const saveEvent = async ({ db, event, nodeId, who, eventName, eventType, network, rootNodeId = '' }) => {
  try {
    if (!db || !event || !event.block) {
      console.error(`Missing required parameters for saveEvent: db=${!!db}, event=${!!event}, block=${!!(event && event.block)}`);
      return false;
    }

    const eventId = createEventId(event);
    
    // Get network info with proper fallbacks - ensure we have valid values
    const networkName = (network?.name || event.context?.network?.name || "unknow").toLowerCase();
    const networkId = (network?.chainId || event.context?.network?.chainId || "0").toString();
    
    // Ensure nodeId is a string
    const safeNodeId = (nodeId || "0").toString();
    // Ensure who is a string
    const safeWho = (who || event.transaction?.from || "unknown").toString();
    
    await db.insert(events).values({
      id: eventId,
      nodeId: safeNodeId,
      rootNodeId: rootNodeId,
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

/**
 * Safe wrapper for handling promises with proper error logging
 */
export const safePromise = async (promise, errorMessage = "Operation failed") => {
  try {
    return await promise;
  } catch (error) {
    console.error(`${errorMessage}:`, error);
    return null;
  }
};

// Helper function to get the appropriate public client for a network
export const getPublicClient = (network) => {
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

export const getNodeData = async (nodeId, context) : Promise<NodeState | null> => {
  try {
    // Create a minimal default response to return in case of RPC errors or other failures
    const defaultResponse: NodeState = {
      basicInfo: {
        nodeId: nodeId.toString(),
        inflation: "0",
        balanceAnchor: "0",
        balanceBudget: "0",
        rootValuationBudget: "0",
        rootValuationReserve: "0",
        membraneId: "0", 
        eligibilityPerSec: "0",
        lastRedistribution: "0",
        balanceOfUser: "0",
        endpointOfUserForNode: "0x0000000000000000000000000000000000000000",
        totalSupply: "0"
      },
      membraneMeta: "",
      membersOfNode: [],
      childrenNodes: [],
      movementEndpoints: [],
      rootPath: [nodeId.toString()], // Include the current node ID to avoid missing rootPath errors
      nodeSignals: {
        signalers: [],
        inflationSignals: [],
        membraneSignals: [],
        redistributionSignals: []
      },
      signals: [] // For backwards compatibility
    };
    
    // Handle case when context might not have network or client
    if (!context?.network) {
      console.log(`Missing network in context for nodeId: ${nodeId}, returning default data`);
      return defaultResponse;
    }
    

    
    const client = context.client || getPublicClient(context?.network?.name);
    if (!client) {
      console.log(`Failed to create client for network: ${context?.network?.name}, returning default data`);
      return defaultResponse;
    }
    
    const contractAddress = deployments?.WillWe?.[context.network.chainId.toString()];
    if (!contractAddress) {
      console.log(`Contract address not found for chain ID: ${context.network.chainId}, returning default data`);
      return defaultResponse;
    }
    
    try {
      const nodeData = await client.readContract({
        address: contractAddress,
        abi: ABIs["WillWe"],
        functionName: "getNodeData",
        args: [nodeId, "0x0000000000000000000000000000000000000000"]
      });
      
      if (!nodeData) {
        console.log(`No data returned from contract for nodeId: ${nodeId}, returning default data`);
        return defaultResponse;
      }
      
      console.log(`Successfully fetched node data for nodeId: ${nodeId}`);
      return nodeData;
    } catch (error) {
      console.log(`Error reading contract data for nodeId ${nodeId}, returning default data:`, error.message || error);
      return defaultResponse;
    }
  } catch (error) {
    console.log(`Unexpected error in getNodeData for ${nodeId}, returning default data:`, error.message || error);
    return defaultResponse; // Always return the default response to prevent crashes
  }
}

export const getRootNodeId = async (nodeId: string, context: any) : Promise<string> => {
  try {
    const nodeData = await getNodeData(nodeId, context);
    
    // If nodeData is null or rootPath is missing, return default
    if (!nodeData || !nodeData.rootPath) {
      console.log(`No valid node data or rootPath for ${nodeId}, returning default root ID`);
      return "0";
    }
    
    // Check if rootPath has elements and get the first one
    const rootNodeId = nodeData.rootPath.length > 0 ? String(nodeData.rootPath[0] || "0") : "0";
    return rootNodeId;
  } catch (error) {
    console.error(`Error getting root node ID for ${nodeId}:`, error);
    return "0";
  }
}

/**
 * Get default network info object with safe values
 */
export const getDefaultNetwork = (contextNetwork) => {
  return {
    name: (contextNetwork?.name || "unknown").toLowerCase(),
    id: (contextnetwork?.chainId || "unknown").toString()
  };
};

/**
 * Safely convert any value to string
 */
export const safeString = (value, defaultValue = "0") => {
  if (value === undefined || value === null) return defaultValue;
  return String(value);
};

/**
 * Safely access event arguments with proper validation
 * @param event The event object
 * @param argName The name of the argument to safely access
 * @param defaultValue Optional default value if arg is missing
 * @returns The argument value or default value
 */
export const safeEventArg = (event, argName, defaultValue = undefined) => {
  if (!event?.args || event.args[argName] === undefined) {
    return defaultValue;
  }
  
  const arg = event.args[argName];
  return arg === null ? defaultValue : arg;
};

/**
 * Safely converts an event argument to string
 * @param event The event object
 * @param argName The name of the argument
 * @param defaultValue Optional default value
 * @returns The argument as string
 */
export const safeEventArgString = (event, argName, defaultValue = "0") => {
  const arg = safeEventArg(event, argName);
  if (arg === undefined || arg === null) return defaultValue;
  return arg.toString();
};

/**
 * Safely stringify objects containing BigInt values for logging
 * @param obj Object to stringify
 * @returns Safe JSON string with BigInt values converted to strings
 */
export const safeBigIntStringify = (obj) => {
  return JSON.stringify(obj, (key, value) => {
    // Convert BigInt values to strings
    if (typeof value === 'bigint') {
      return value.toString();
    }
    return value;
  }, 2);
};
