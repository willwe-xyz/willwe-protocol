import { onchainTable, onchainEnum, relations, index } from "ponder";
import { zeroAddress } from "viem"  

export const Network = onchainEnum("network", ["mainnet", "rinkeby", "ropsten", "kovan", "goerli", "localhost"]);
export const EventType = onchainEnum("eventType", ["redistribution", "redistributionSignal", "membraneSignal", "mint", "burn", "transfer", "approval", "approvalForAll", "configSignal", "inflationMinted", "inflationRateChanged", "crosschainTransfer", "newNode", "newRoot"]);
export const EndpointType = onchainEnum("endpointType", ["userOwned", "movement"]);
export const SignalType = onchainEnum("signalType", ["membrane", "inflation", "redistribution"]);

export const events = onchainTable("events", (t) => ({
  id: t.text().primaryKey(),
  nodeId: t.text(),
  who: t.text(),
  eventName: t.text(),
  eventType: EventType("eventType"),
  when: t.numeric(),
  createdBlockNumber: t.numeric(),
  network: t.text(),
  networkId: t.text(),
}), (table) => ({
  nodeIdx: index().on(table.nodeId),
  whox: index().on(table.who)
}));


export const memberships = onchainTable("memberships", (t) => ({
  id: t.text().primaryKey(),
  nodeId: t.text(),
  who: t.text(),
  when: t.numeric(),
  isValid: t.boolean().notNull().default(true),
}), (table) => ({
  nodeIdx: index().on(table.nodeId),
  whox: index().on(table.who)
}));

export const redistributionPreference = onchainTable("redistributionEvents", (t) => ({
  id: t.text().primaryKey(),
  nodeId: t.text(),
  signalOrigin: t.text(),
  sender: t.text(),
  preferences: t.text().array(),
  when: t.numeric(),
  createdBlockNumber: t.numeric(),
  network: t.text(),
  networkId: t.text(),
}));

export const membraneSignals = onchainTable("membraneSignals", (t) => ({
  id: t.text().primaryKey(),
  nodeId: t.text(),
  who: t.text(),
  signalOrigin: t.text(zeroAddress),
  membraneId: t.text(),
}))

export const inflationSignals = onchainTable("inflationSignals", (t) => ({
  id: t.text().primaryKey(),
  nodeId: t.text(),
  who: t.text(),
  signalOrigin: t.text(zeroAddress),
  inflationValue: t.text(),
}))

export const nodeSignals = onchainTable("nodeSignals", (t) => ({
  id: t.text().primaryKey(),
  nodeId: t.text(),
  who: t.text(),
  signalType: SignalType("signalType"),
  signalValue: t.text(),
  currentPrevalence: t.text(), // Total support for this signal
  when: t.numeric(),
  network: t.text(),
  networkId: t.text(),
}), (table) => ({
  nodeIdx: index().on(table.nodeId),
  whox: index().on(table.who),
  signalTypeIdx: index().on(table.signalType)
}));

export const signatures = onchainTable("signatures", (t) => ({
  id: t.text().primaryKey(),
  nodeId: t.text(),
  signer: t.text(),
  signature: t.text(),
  signatureQueueHash: t.text(),
  submitted: t.boolean().default(false),
  when: t.numeric(),
  network: t.text(),
  networkId: t.text(),
}), (table) => ({
  SQx: index().on(table.signatureQueueHash),
  nodeIdx: index().on(table.nodeId)
}));

export const MovementType = onchainEnum("MovementType", ["Revert", "AgentMajority", "EnergeticMajority"]);
export const SQState = onchainEnum("SQState", ["None", "Initialized", "Valid", "Executed", "Stale"]);

export const movements = onchainTable("movements", (t) => ({
  id: t.text().primaryKey(),
  nodeId: t.text(),
  category: MovementType("MovementType"),
  initiator: t.text(),
  exeAccount: t.text(),
  viaNode: t.numeric(),
  expiresAt: t.numeric(),
  description: t.text(),
  executedPayload: t.text(),
  createdBlockNumber: t.numeric(),
  network: t.text(),
  networkId: t.text(),
}));

export const signatureQueues = onchainTable("signatureQueues", (t) => ({
  id: t.text().primaryKey(),
  state: SQState("SQState"),
  movementId: t.text(), // References the movement table
  signers: t.text().array(),
  signatures: t.text().array(),
  createdBlockNumber: t.numeric(),
  network: t.text(),
  networkId: t.text(),
}));



export const nodes = onchainTable("nodes", (t) => ({
  nodeId: t.text().primaryKey(),
  inflation: t.text(),
  reserve: t.text(),
  budget: t.text(),
  rootValuationBudget: t.text(),
  rootValuationReserve: t.text(),
  membraneId: t.text(),
  eligibilityPerSec: t.text(),
  lastRedistributionTime: t.text(),
  totalSupply: t.text(),
  membraneMeta: t.text(), 
  membersOfNode: t.text().array(), 
  childrenNodes: t.text().array(), 
  movementEndpoints: t.text().array(), 
  rootPath: t.text().array(), 
  signals: t.text().array(),
  createdAt: t.numeric(),
  updatedAt: t.numeric(),
  createdBlockNumber: t.numeric(),
  network: t.text(),
  networkId: t.text()
}));

export const nodesRelations = relations(nodes, ({ many, one }) => ({
  childrenNodes: many(nodes),
  movementEndpoints: many(endpoints),
  rootPath: many(nodes),
  membersOfNode: many(memberships),
  membrane: one(membranes),
  redistributionPreferences: many(redistributionPreference),
  inflationSignals: many(inflationSignals),
  membraneSignals: many(membraneSignals),
  signals: many(nodeSignals),
  signatures: many(signatures),
  movements: many(movements),
  signatureQueues: many(signatureQueues),
  events: many(events)
}));

export const endpoints = onchainTable("endpoints", (t) => ({
  id: t.text().primaryKey(),
  nodeId: t.numeric(),
  endpointId: t.numeric(),
  owner: t.text(),
  endpointType: EndpointType("endpointType"),
  endpointAddress: t.text(),
  createdAt: t.numeric(),
  createdBlockNumber: t.numeric(),
  network: t.text(),
  networkId: t.text(),
}));


export const membranes = onchainTable("membranes", (t) => ({
  id: t.text().primaryKey(),
  membraneId: t.numeric(),
  creator: t.text(),
  metadataCID: t.text(),
  data: t.text(),
  tokens: t.text().array(),
  balances: t.text().array(),
  createdAt: t.numeric(),
  createdBlockNumber: t.numeric(),
  network: t.text(),
  networkId: t.text(),
}));


export const WillTokenPrice = onchainTable("WillTokenPrice", (t) => ({
  id: t.text().primaryKey(), 
  timestamp: t.timestamp(), 
  price: t.numeric(),
  createdBlockNumber: t.numeric(),
  network: t.text(),
  networkId: t.text(),
}));

// Add chat_messages table to the schema
export const chatMessages = onchainTable("chat_messages", (t) => ({
  id: t.text().primaryKey(),
  nodeId: t.text(), // The node this chat message belongs to
  sender: t.text(), // Address or identifier of the sender
  content: t.text(), // Message content
  timestamp: t.numeric(), // When the message was sent
  networkId: t.text(), // Network ID for multi-chain support
}), (table) => ({
  nodeIdIdx: index().on(table.nodeId),
  timestampIdx: index().on(table.timestamp),
}));

// Add relations for chat messages
export const chatMessagesRelations = relations(chatMessages, ({ one }) => ({
  node: one(nodes, {
    fields: [chatMessages.nodeId],
    references: [nodes.nodeId]
  }),
}));

