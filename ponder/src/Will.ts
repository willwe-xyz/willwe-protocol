// This file contains event handlers for Will Token price updates
import { ponder } from "ponder:registry";
import { WillTokenPrice } from "../ponder.schema";

export const handlePriceUpdate = async ({ event, context }) => {
  const { db } = context;
  console.log("Will Token Price Update:", event.args);

  try {
    // Create a unique ID for the price update
    const priceId = `price-${event.block.timestamp.toString()}-${event.log.logIndex}`;
    
    // Insert the price update
    await db.insert(WillTokenPrice).values({
      id: priceId,
      timestamp: new Date(Number(event.block.timestamp) * 1000), // Convert to JS timestamp
      price: event.args.price?.toString() || "0", // Make sure price is always a string
      createdBlockNumber: event.block.number,
      network: context.network.name.toLowerCase()
    }).onConflictDoNothing();

    console.log("Inserted Will Token Price:", priceId, "with price:", event.args.price?.toString());
  } catch (error) {
    console.error("Error in handlePriceUpdate:", error);
  }
};