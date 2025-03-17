/**
 * Common utility functions shared across handlers
 */
import { events } from "../ponder.schema";

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
export const saveEvent = async ({ db, event, nodeId, who, eventName, eventType, network }) => {
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

/**
 * Get default network info object with safe values
 */
export const getDefaultNetwork = (contextNetwork) => {
  return {
    name: (contextNetwork?.name || "optimismsepolia").toLowerCase(),
    id: (contextNetwork?.id || "11155420").toString()
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
