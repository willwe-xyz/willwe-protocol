import { db } from "ponder:api";
import schema from "ponder:schema";
import { Hono } from "hono";
import { eq, desc, and, like, or } from "drizzle-orm";

const app = new Hono();

// Get a node by ID
app.get("/node/:nodeId", async (c) => {
  const nodeId = c.req.param("nodeId");
  
  try {
    // Fetch the node
    const nodeResult = await db
      .select()
      .from(schema.nodes)
      .where(eq(schema.nodes.nodeId, nodeId))
      .limit(1);
      
    if (nodeResult.length === 0) {
      return c.json({ error: "Node not found" }, 404);
    }
    
    const node = nodeResult[0];
    
    // Fetch related data
    const memberships = await db
      .select()
      .from(schema.memberships)
      .where(eq(schema.memberships.nodeId, nodeId));
      
    // Fetch node signals
    const signals = await db
      .select()
      .from(schema.nodeSignals)
      .where(eq(schema.nodeSignals.nodeId, nodeId))
      .orderBy(desc(schema.nodeSignals.when))
      .limit(100);
      
    // Fetch events
    const events = await db
      .select()
      .from(schema.events)
      .where(eq(schema.events.nodeId, nodeId))
      .orderBy(desc(schema.events.when))
      .limit(50);
      
    // Return combined data
    return c.json({
      node,
      memberships,
      signals,
      events
    });
  } catch (error) {
    console.error(`Error fetching node ${nodeId}:`, error);
    return c.json({ error: "Internal server error" }, 500);
  }
});

// Get all nodes with pagination
app.get("/nodes", async (c) => {
  const limit = parseInt(c.req.query("limit") || "20");
  const offset = parseInt(c.req.query("offset") || "0");
  const networkId = c.req.query("networkId");
  
  try {
    let query = db
      .select()
      .from(schema.nodes)
      .limit(limit)
      .offset(offset)
      .orderBy(desc(schema.nodes.createdAt));
    
    // Add network filter if specified
    if (networkId) {
      query = query.where(eq(schema.nodes.networkId, networkId));
    }
    
    const nodes = await query;
    
    // Get total count (for pagination)
    const countQuery = networkId 
      ? await db.select().from(schema.nodes).where(eq(schema.nodes.networkId, networkId))
      : await db.select().from(schema.nodes);
    
    return c.json({
      nodes,
      meta: {
        total: countQuery.length,
        limit,
        offset
      }
    });
  } catch (error) {
    console.error("Error fetching nodes:", error);
    return c.json({ error: "Internal server error" }, 500);
  }
});

// Get events with filtering and pagination
app.get("/events", async (c) => {
  const limit = parseInt(c.req.query("limit") || "50");
  const offset = parseInt(c.req.query("offset") || "0");
  const nodeId = c.req.query("nodeId");
  const who = c.req.query("who");
  const eventType = c.req.query("eventType");
  const networkId = c.req.query("networkId");
  
  try {
    let query = db
      .select()
      .from(schema.events)
      .limit(limit)
      .offset(offset)
      .orderBy(desc(schema.events.when));
    
    // Build filters
    const filters = [];
    if (nodeId) filters.push(eq(schema.events.nodeId, nodeId));
    if (who) filters.push(eq(schema.events.who, who));
    if (eventType) filters.push(eq(schema.events.eventType, eventType));
    if (networkId) filters.push(eq(schema.events.networkId, networkId));
    
    // Apply filters if any
    if (filters.length > 0) {
      query = query.where(and(...filters));
    }
    
    const events = await query;
    
    return c.json({
      events,
      meta: {
        limit,
        offset
      }
    });
  } catch (error) {
    console.error("Error fetching events:", error);
    return c.json({ error: "Internal server error" }, 500);
  }
});

// Get user activity
app.get("/user/:address", async (c) => {
  const address = c.req.param("address").toLowerCase();
  const limit = parseInt(c.req.query("limit") || "50");
  
  try {
    // Get memberships
    const memberships = await db
      .select()
      .from(schema.memberships)
      .where(eq(schema.memberships.who, address))
      .limit(limit);
      
    // Get events
    const events = await db
      .select()
      .from(schema.events)
      .where(eq(schema.events.who, address))
      .orderBy(desc(schema.events.when))
      .limit(limit);
      
    // Get signals
    const signals = await db
      .select()
      .from(schema.nodeSignals)
      .where(eq(schema.nodeSignals.who, address))
      .orderBy(desc(schema.nodeSignals.when))
      .limit(limit);
    
    return c.json({
      address,
      memberships,
      events,
      signals
    });
  } catch (error) {
    console.error(`Error fetching data for user ${address}:`, error);
    return c.json({ error: "Internal server error" }, 500);
  }
});

// Search API
app.get("/search", async (c) => {
  const query = c.req.query("q");
  const limit = parseInt(c.req.query("limit") || "20");
  
  if (!query || query.length < 2) {
    return c.json({ error: "Query must be at least 2 characters" }, 400);
  }
  
  try {
    // Search nodes
    const nodes = await db
      .select()
      .from(schema.nodes)
      .where(like(schema.nodes.membraneMeta, `%${query}%`))
      .limit(limit);
    
    // Search users (from events)
    const users = await db
      .select({ address: schema.events.who })
      .from(schema.events)
      .where(like(schema.events.who, `%${query}%`))
      .groupBy(schema.events.who)
      .limit(limit);
    
    return c.json({
      nodes,
      users
    });
  } catch (error) {
    console.error(`Error searching for "${query}":`, error);
    return c.json({ error: "Internal server error" }, 500);
  }
});

// Get membranes
app.get("/membranes", async (c) => {
  const limit = parseInt(c.req.query("limit") || "20");
  const offset = parseInt(c.req.query("offset") || "0");
  const creator = c.req.query("createdBy");
  
  try {
    const query = db
      .select()
      .from(schema.membranes)
      .where(creator ? eq(schema.membranes.creator, creator) : undefined)
      .limit(limit)
      .offset(offset)
      .orderBy(desc(schema.membranes.createdAt));
    
    const membranes = await query;
      
    return c.json({
      membranes,
      meta: {
        limit,
        offset
      }
    });
  } catch (error) {
    console.error("Error fetching membranes:", error);
    return c.json({ error: "Internal server error" }, 500);
  }
});

// Get movements
app.get("/movements", async (c) => {
  const nodeId = c.req.query("nodeId");
  const limit = parseInt(c.req.query("limit") || "20");
  const offset = parseInt(c.req.query("offset") || "0");
  
  try {
    const query = nodeId 
      ? db.select().from(schema.movements)
        .where(eq(schema.movements.nodeId, nodeId))
        .limit(limit)
        .offset(offset)
        .orderBy(desc(schema.movements.createdBlockNumber))
      : db.select().from(schema.movements)
        .limit(limit)
        .offset(offset)
        .orderBy(desc(schema.movements.createdBlockNumber));
    
    const movements = await query;
    
    // For each movement, get its signature queue if it exists
    const movementsWithQueues = await Promise.all(
      movements.map(async (movement) => {
        const queues = await db
          .select()
          .from(schema.signatureQueues)
          .where(eq(schema.signatureQueues.movementId, movement.id));
          
        return {
          ...movement,
          signatureQueues: queues
        };
      })
    );
    
    return c.json({
      movements: movementsWithQueues,
      meta: {
        limit,
        offset
      }
    });
  } catch (error) {
    console.error("Error fetching movements:", error);
    return c.json({ error: "Internal server error" }, 500);
  }
});



export default app;