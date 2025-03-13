import { db } from "ponder:api";
import schema from "ponder:schema";
import { Hono } from "hono";
import { eq } from "drizzle-orm";


const app = new Hono();
 
app.get("/node/:nodeId", async (c) => {
  const nodeId = c.req.param("nodeId");
 
  const account = await db
    .select()
    .from(schema.nodes)
    .where(eq(schema.nodes.nodeId, nodeId))
    .limit(1);
 
  return c.json(account);
});
 
export default app;