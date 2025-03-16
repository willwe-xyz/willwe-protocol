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
