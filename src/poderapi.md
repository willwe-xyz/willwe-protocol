This file contains ponder API docs ane examples.


Indexing function API
Indexing functions are user-defined functions that receive blockchain data (a log, block, transaction, trace, or transfer) and insert data into the database. You can register indexing functions within any .ts file inside the src/ directory.

Registration
To register an indexing function, use the .on() method of the ponder object exported from "ponder:registry".

Values returned by indexing functions are ignored.

src/index.ts

import { ponder } from "ponder:registry";
 
ponder.on("ContractName:EventName", async ({ event, context }) => {
  const { db, network, client, contracts } = context;
 
  // ...
});
Log event
Log events are specified with "ContractName:EventName".

src/index.ts

import { ponder } from "ponder:registry";
 
ponder.on("ContractName:EventName", async ({ event, context }) => {
  // ...
});
The event argument contains the decoded log arguments and the raw log, block, and transaction.

type LogEvent = {
  name: string;
  args: Args;
  log: Log;
  block: Block;
  transaction: Transaction;
  // Enabled using `includeTransactionReceipts` in contract config
  transactionReceipt?: TransactionReceipt;
};

Log event arguments
The event.args object contains decoded log.topics and log.data decoded using Viem's decodeEventLog function.

/** Sample `args` type for an ERC20 Transfer event. */
type Args = {
  from: `0x${string}`;
  to: `0x${string}`;
  value: bigint;
};

Call trace event
Call trace events are specified using "ContractName.functionName()".

The includeCallTraces contract option must be enabled to use call trace events.

src/index.ts

import { ponder } from "ponder:registry";
 
ponder.on("ContractName.functionName()", async ({ event, context }) => {
  // ...
});
The event argument contains the decoded call trace args and result and the raw trace, block, and transaction.

type TraceEvent = {
  name: string;
  args: Args;
  result: Result;
  trace: Trace;
  block: Block;
  transaction: Transaction;
  // Enabled using `includeTransactionReceipts` in contract config
  transactionReceipt?: TransactionReceipt;
};

Call trace event arguments
The event.args and event.result objects contain trace.input and trace.output decoded using Viem's decodeFunctionData and decodeFunctionResult functions, respectively.

Transaction event
Transaction events are specified using "AccountName:transaction:from" or "AccountName:transaction:to".

src/index.ts

import { ponder } from "ponder:registry";
 
ponder.on("AccountName:transaction:from", async ({ event, context }) => {
  // ...
});
The event argument contains the raw block, transaction, and transaction receipt.

type TransactionEvent = {
  block: Block;
  transaction: Transaction;
  transactionReceipt: TransactionReceipt;
};

Transfer event
Native transfer events are specified using "AccountName:transfer:from" or "AccountName:transfer:to".

src/index.ts

import { ponder } from "ponder:registry";
 
ponder.on("AccountName:transfer:from", async ({ event, context }) => {
  // ...
});
The event argument contains the transfer and raw block, transaction, and trace.

type TransferEvent = {
  transfer: {
    from: `0x${string}`;
    to: `0x${string}`;
    value: bigint;
  };
  block: Block;
  transaction: Transaction;
  trace: Trace;
  // Enabled using `includeTransactionReceipts` in account config
  transactionReceipt?: TransactionReceipt;
};

Block event
Block events are specified using "SourceName:block".

src/index.ts

import { ponder } from "ponder:registry";
 
ponder.on("SourceName:block", async ({ event, context }) => {
  // ...
});
The event argument contains the raw block.

type BlockEvent = {
  block: Block;
};

Event types
Event types

/** The block containing the transaction that emitted the log being processed. */
type Block = {
  /** Base fee per gas */
  baseFeePerGas: bigint | null;
  /** "Extra data" field of this block */
  extraData: `0x${string}`;
  /** Maximum gas allowed in this block */
  gasLimit: bigint;
  /** Total used gas by all transactions in this block */
  gasUsed: bigint;
  /** Block hash */
  hash: `0x${string}`;
  /** Logs bloom filter */
  logsBloom: `0x${string}`;
  /** Address that received this block’s mining rewards */
  miner: `0x${string}`;
  /** Block number */
  number: bigint;
  /** Parent block hash */
  parentHash: `0x${string}`;
  /** Root of the this block’s receipts trie */
  receiptsRoot: `0x${string}`;
  /** Size of this block in bytes */
  size: bigint;
  /** Root of this block’s final state trie */
  stateRoot: `0x${string}`;
  /** Unix timestamp of when this block was collated */
  timestamp: bigint;
  /** Total difficulty of the chain until this block */
  totalDifficulty: bigint | null;
  /** Root of this block’s transaction trie */
  transactionsRoot: `0x${string}`;
};
 
/** The transaction that emitted the log being processed. */
type Transaction = {
  /** Transaction sender */
  from: `0x${string}`;
  /** Gas provided for transaction execution */
  gas: bigint;
  /** Base fee per gas. */
  gasPrice?: bigint | undefined;
  /** Hash of this transaction */
  hash: `0x${string}`;
  /** Contract code or a hashed method call */
  input: `0x${string}`;
  /** Total fee per gas in wei (gasPrice/baseFeePerGas + maxPriorityFeePerGas). */
  maxFeePerGas?: bigint | undefined;
  /** Max priority fee per gas (in wei). */
  maxPriorityFeePerGas?: bigint | undefined;
  /** Unique number identifying this transaction */
  nonce: number;
  /** Transaction recipient or `null` if deploying a contract */
  to: `0x${string}` | null;
  /** Index of this transaction in the block */
  transactionIndex: number;
  /** Value in wei sent with this transaction */
  value: bigint;
};
 
/** A confirmed Ethereum transaction receipt. */
type TransactionReceipt = {
  /** Address of new contract or `null` if no contract was created */
  contractAddress: Address | null;
  /** Gas used by this and all preceding transactions in this block */
  cumulativeGasUsed: bigint;
  /** Pre-London, it is equal to the transaction's gasPrice. Post-London, it is equal to the actual gas price paid for inclusion. */
  effectiveGasPrice: bigint;
  /** Transaction sender */
  from: Address;
  /** Gas used by this transaction */
  gasUsed: bigint;
  /** List of log objects generated by this transaction */
  logs: Log[];
  /** Logs bloom filter */
  logsBloom: Hex;
  /** `success` if this transaction was successful or `reverted` if it failed */
  status: "success" | "reverted";
  /** Transaction recipient or `null` if deploying a contract */
  to: Address | null;
  /** Transaction type */
  type: TransactionType;
};
 
/** The log being processed. */
type Log = {
  /** Globally unique identifier for this log (`${blockHash}-${logIndex}`). */
  id: string;
  /** The address from which this log originated */
  address: `0x${string}`;
  /** Contains the non-indexed arguments of the log */
  data: `0x${string}`;
  /** Index of this log within its block */
  logIndex: number;
  /** `true` if this log has been removed in a chain reorganization */
  removed: boolean;
  /** List of order-dependent topics */
  topics: [`0x${string}`, ...`0x${string}`[]] | [];
};
 
type Trace = {
  /** Globally unique identifier for this trace (`${transactionHash}-${tracePosition}`) */
  id: string;
  /** The type of the call. */
  type:
    | "CALL"
    | "CALLCODE"
    | "DELEGATECALL"
    | "STATICCALL"
    | "CREATE"
    | "CREATE2"
    | "SELFDESTRUCT";
  /** The address of that initiated the call. */
  from: Address;
  /** The address of the contract that was called. */
  to: Address | null;
  /** How much gas was left before the call. */
  gas: bigint;
  /** How much gas was used by the call. */
  gasUsed: bigint;
  /** Calldata input. */
  input: Hex;
  /** Output of the call, if any. */
  output?: Hex;
  /** Error message, if any. */
  error?: string;
  /** Why this call reverted, if it reverted. */
  revertReason?: string;
  /** Value transferred. */
  value: bigint | null;
  /** Index of this trace in the transaction. */
  traceIndex: number;
  /** Number of subcalls. */
  subcalls: number;
};
Context
The context argument passed to each indexing function contains database model objects and helper objects based on your config.

At runtime, the indexing engine uses a different context object depending on the network the current event was emitted on. The TypeScript types for the context object reflect this by creating a union of possible types for context.network and context.contracts.

type Context = {
  db: Database;
  network: { name: string; chainId: number };
  client: ReadOnlyClient;
  contracts: Record<
    string,
    { abi: Abi; address?: `0x${string}`; startBlock?: number; endBlock?: number; }
  >;
};

Database
The context.db object is a live database connection. Read more about writing to the database.

src/index.ts

import { ponder } from "ponder:registry";
import { persons, dogs } from "ponder:schema";
 
ponder.on("Neighborhood:NewNeighbor", async ({ event, context }) => {
  await context.db.insert(persons).values({ name: "bob", age: 30 });
  await context.db.insert(dogs).values({ name: "jake", ownerName: "bob" });
  const jake = await context.db.find(dogs, { name: "jake" });
});
Network
The context.network object includes information about the network that the current event is from. The object is strictly typed according to the networks you defined in your config.

src/index.ts

ponder.on("UniswapV3Factory:Ownership", async ({ event, context }) => {
  context.network;
  //      ^? { name: "mainnet", chainId 1 } | { name: "base", chainId 8453 }
 
  if (context.network.name === "mainnet") {
    // Do mainnet-specific stuff!
  }
});
Client
See the Read contract data guide for more details.

Contracts
See the Read contract data guide for more details.

"setup" event
You can also define a setup function for each contract that runs before indexing begins.

The indexing function does not receive an event argument, only context.
If you read from contracts in a "setup" indexing function, the blockNumber for the request is set to the contract's startBlock.
For example, you might have a singleton World record that occasionally gets updated in indexing functions.

src/index.ts

import { ponder } from "ponder:registry";
import { world } from "ponder:schema";
 
ponder.on("FunGame:NewPlayer", async ({ context }) => {
  await context.db
    .insert(world)
    .values({ id: 1, playerCount: 0 })
    .onConflictDoUpdate((row) => ({
      playerCount: row.playerCount + 1,
    }));
});
Without the "setup" event, you need to upsert the record in each indexing function that attempts to use it, which is clunky and bad for performance. Instead, use the "setup" event to create the singleton record once at the beginning of indexing.

src/index.ts

import { ponder } from "ponder:registry";
import { world } from "ponder:schema";
 
ponder.on("FunGame:setup", async ({ context }) => {
  await context.db.insert(world).values({
    id: 1,
    playerCount: 0,
  });
});
 
ponder.on("FunGame:NewPlayer", async ({ context }) => {
  await context.db
    .update(world, { id: 1 })
    .set((row) => ({
      playerCount: row.playerCount + 1,
  }));
});


//////////////////////////////

Indexing function API
Indexing functions are user-defined functions that receive blockchain data (a log, block, transaction, trace, or transfer) and insert data into the database. You can register indexing functions within any .ts file inside the src/ directory.

Registration
To register an indexing function, use the .on() method of the ponder object exported from "ponder:registry".

Values returned by indexing functions are ignored.

src/index.ts

import { ponder } from "ponder:registry";
 
ponder.on("ContractName:EventName", async ({ event, context }) => {
  const { db, network, client, contracts } = context;
 
  // ...
});
Log event
Log events are specified with "ContractName:EventName".

src/index.ts

import { ponder } from "ponder:registry";
 
ponder.on("ContractName:EventName", async ({ event, context }) => {
  // ...
});
The event argument contains the decoded log arguments and the raw log, block, and transaction.

type LogEvent = {
  name: string;
  args: Args;
  log: Log;
  block: Block;
  transaction: Transaction;
  // Enabled using `includeTransactionReceipts` in contract config
  transactionReceipt?: TransactionReceipt;
};

Log event arguments
The event.args object contains decoded log.topics and log.data decoded using Viem's decodeEventLog function.

/** Sample `args` type for an ERC20 Transfer event. */
type Args = {
  from: `0x${string}`;
  to: `0x${string}`;
  value: bigint;
};

Call trace event
Call trace events are specified using "ContractName.functionName()".

The includeCallTraces contract option must be enabled to use call trace events.

src/index.ts

import { ponder } from "ponder:registry";
 
ponder.on("ContractName.functionName()", async ({ event, context }) => {
  // ...
});
The event argument contains the decoded call trace args and result and the raw trace, block, and transaction.

type TraceEvent = {
  name: string;
  args: Args;
  result: Result;
  trace: Trace;
  block: Block;
  transaction: Transaction;
  // Enabled using `includeTransactionReceipts` in contract config
  transactionReceipt?: TransactionReceipt;
};

Call trace event arguments
The event.args and event.result objects contain trace.input and trace.output decoded using Viem's decodeFunctionData and decodeFunctionResult functions, respectively.

Transaction event
Transaction events are specified using "AccountName:transaction:from" or "AccountName:transaction:to".

src/index.ts

import { ponder } from "ponder:registry";
 
ponder.on("AccountName:transaction:from", async ({ event, context }) => {
  // ...
});
The event argument contains the raw block, transaction, and transaction receipt.

type TransactionEvent = {
  block: Block;
  transaction: Transaction;
  transactionReceipt: TransactionReceipt;
};

Transfer event
Native transfer events are specified using "AccountName:transfer:from" or "AccountName:transfer:to".

src/index.ts

import { ponder } from "ponder:registry";
 
ponder.on("AccountName:transfer:from", async ({ event, context }) => {
  // ...
});
The event argument contains the transfer and raw block, transaction, and trace.

type TransferEvent = {
  transfer: {
    from: `0x${string}`;
    to: `0x${string}`;
    value: bigint;
  };
  block: Block;
  transaction: Transaction;
  trace: Trace;
  // Enabled using `includeTransactionReceipts` in account config
  transactionReceipt?: TransactionReceipt;
};

Block event
Block events are specified using "SourceName:block".

src/index.ts

import { ponder } from "ponder:registry";
 
ponder.on("SourceName:block", async ({ event, context }) => {
  // ...
});
The event argument contains the raw block.

type BlockEvent = {
  block: Block;
};

Event types
Event types

/** The block containing the transaction that emitted the log being processed. */
type Block = {
  /** Base fee per gas */
  baseFeePerGas: bigint | null;
  /** "Extra data" field of this block */
  extraData: `0x${string}`;
  /** Maximum gas allowed in this block */
  gasLimit: bigint;
  /** Total used gas by all transactions in this block */
  gasUsed: bigint;
  /** Block hash */
  hash: `0x${string}`;
  /** Logs bloom filter */
  logsBloom: `0x${string}`;
  /** Address that received this block’s mining rewards */
  miner: `0x${string}`;
  /** Block number */
  number: bigint;
  /** Parent block hash */
  parentHash: `0x${string}`;
  /** Root of the this block’s receipts trie */
  receiptsRoot: `0x${string}`;
  /** Size of this block in bytes */
  size: bigint;
  /** Root of this block’s final state trie */
  stateRoot: `0x${string}`;
  /** Unix timestamp of when this block was collated */
  timestamp: bigint;
  /** Total difficulty of the chain until this block */
  totalDifficulty: bigint | null;
  /** Root of this block’s transaction trie */
  transactionsRoot: `0x${string}`;
};
 
/** The transaction that emitted the log being processed. */
type Transaction = {
  /** Transaction sender */
  from: `0x${string}`;
  /** Gas provided for transaction execution */
  gas: bigint;
  /** Base fee per gas. */
  gasPrice?: bigint | undefined;
  /** Hash of this transaction */
  hash: `0x${string}`;
  /** Contract code or a hashed method call */
  input: `0x${string}`;
  /** Total fee per gas in wei (gasPrice/baseFeePerGas + maxPriorityFeePerGas). */
  maxFeePerGas?: bigint | undefined;
  /** Max priority fee per gas (in wei). */
  maxPriorityFeePerGas?: bigint | undefined;
  /** Unique number identifying this transaction */
  nonce: number;
  /** Transaction recipient or `null` if deploying a contract */
  to: `0x${string}` | null;
  /** Index of this transaction in the block */
  transactionIndex: number;
  /** Value in wei sent with this transaction */
  value: bigint;
};
 
/** A confirmed Ethereum transaction receipt. */
type TransactionReceipt = {
  /** Address of new contract or `null` if no contract was created */
  contractAddress: Address | null;
  /** Gas used by this and all preceding transactions in this block */
  cumulativeGasUsed: bigint;
  /** Pre-London, it is equal to the transaction's gasPrice. Post-London, it is equal to the actual gas price paid for inclusion. */
  effectiveGasPrice: bigint;
  /** Transaction sender */
  from: Address;
  /** Gas used by this transaction */
  gasUsed: bigint;
  /** List of log objects generated by this transaction */
  logs: Log[];
  /** Logs bloom filter */
  logsBloom: Hex;
  /** `success` if this transaction was successful or `reverted` if it failed */
  status: "success" | "reverted";
  /** Transaction recipient or `null` if deploying a contract */
  to: Address | null;
  /** Transaction type */
  type: TransactionType;
};
 
/** The log being processed. */
type Log = {
  /** Globally unique identifier for this log (`${blockHash}-${logIndex}`). */
  id: string;
  /** The address from which this log originated */
  address: `0x${string}`;
  /** Contains the non-indexed arguments of the log */
  data: `0x${string}`;
  /** Index of this log within its block */
  logIndex: number;
  /** `true` if this log has been removed in a chain reorganization */
  removed: boolean;
  /** List of order-dependent topics */
  topics: [`0x${string}`, ...`0x${string}`[]] | [];
};
 
type Trace = {
  /** Globally unique identifier for this trace (`${transactionHash}-${tracePosition}`) */
  id: string;
  /** The type of the call. */
  type:
    | "CALL"
    | "CALLCODE"
    | "DELEGATECALL"
    | "STATICCALL"
    | "CREATE"
    | "CREATE2"
    | "SELFDESTRUCT";
  /** The address of that initiated the call. */
  from: Address;
  /** The address of the contract that was called. */
  to: Address | null;
  /** How much gas was left before the call. */
  gas: bigint;
  /** How much gas was used by the call. */
  gasUsed: bigint;
  /** Calldata input. */
  input: Hex;
  /** Output of the call, if any. */
  output?: Hex;
  /** Error message, if any. */
  error?: string;
  /** Why this call reverted, if it reverted. */
  revertReason?: string;
  /** Value transferred. */
  value: bigint | null;
  /** Index of this trace in the transaction. */
  traceIndex: number;
  /** Number of subcalls. */
  subcalls: number;
};
Context
The context argument passed to each indexing function contains database model objects and helper objects based on your config.

At runtime, the indexing engine uses a different context object depending on the network the current event was emitted on. The TypeScript types for the context object reflect this by creating a union of possible types for context.network and context.contracts.

type Context = {
  db: Database;
  network: { name: string; chainId: number };
  client: ReadOnlyClient;
  contracts: Record<
    string,
    { abi: Abi; address?: `0x${string}`; startBlock?: number; endBlock?: number; }
  >;
};

Database
The context.db object is a live database connection. Read more about writing to the database.

src/index.ts

import { ponder } from "ponder:registry";
import { persons, dogs } from "ponder:schema";
 
ponder.on("Neighborhood:NewNeighbor", async ({ event, context }) => {
  await context.db.insert(persons).values({ name: "bob", age: 30 });
  await context.db.insert(dogs).values({ name: "jake", ownerName: "bob" });
  const jake = await context.db.find(dogs, { name: "jake" });
});
Network
The context.network object includes information about the network that the current event is from. The object is strictly typed according to the networks you defined in your config.

src/index.ts

ponder.on("UniswapV3Factory:Ownership", async ({ event, context }) => {
  context.network;
  //      ^? { name: "mainnet", chainId 1 } | { name: "base", chainId 8453 }
 
  if (context.network.name === "mainnet") {
    // Do mainnet-specific stuff!
  }
});
Client
See the Read contract data guide for more details.

Contracts
See the Read contract data guide for more details.

"setup" event
You can also define a setup function for each contract that runs before indexing begins.

The indexing function does not receive an event argument, only context.
If you read from contracts in a "setup" indexing function, the blockNumber for the request is set to the contract's startBlock.
For example, you might have a singleton World record that occasionally gets updated in indexing functions.

src/index.ts

import { ponder } from "ponder:registry";
import { world } from "ponder:schema";
 
ponder.on("FunGame:NewPlayer", async ({ context }) => {
  await context.db
    .insert(world)
    .values({ id: 1, playerCount: 0 })
    .onConflictDoUpdate((row) => ({
      playerCount: row.playerCount + 1,
    }));
});
Without the "setup" event, you need to upsert the record in each indexing function that attempts to use it, which is clunky and bad for performance. Instead, use the "setup" event to create the singleton record once at the beginning of indexing.

src/index.ts

import { ponder } from "ponder:registry";
import { world } from "ponder:schema";
 
ponder.on("FunGame:setup", async ({ context }) => {
  await context.db.insert(world).values({
    id: 1,
    playerCount: 0,
  });
});
 
ponder.on("FunGame:NewPlayer", async ({ context }) => {
  await context.db
    .update(world, { id: 1 })
    .set((row) => ({
      playerCount: row.playerCount + 1,
  }));
});

/////////////////////////////////////////////////////

Schema API
The ponder.schema.ts file defines your database tables and their relationships. Tables defined in this file are used to store indexed blockchain data and are automatically exposed via the GraphQL API.

File requirements
The ponder.schema.ts must use named exports for tables, enums, and relations, and these objects must be created using the corresponding functions exported by ponder.

ponder.schema.ts

import { onchainTable } from "ponder";
 
export const pets = onchainTable("pets", (t) => ({
  name: t.text().primaryKey(),
  age: t.integer().notNull(),
}));
onchainTable
The onchainTable function accepts three positional arguments.

Argument	Type	Description
name	string	The SQL table name. Use snake_case.
columns	(t: TableBuilder) => Record<string, Column>	A function that returns column definitions.
constraints?	(table: Table) => Record<string, Constraint>	Optional function that returns table constraints like composite primary keys and indexes.
ponder.schema.ts

import { onchainTable } from "ponder";
 
export const transferEvents = onchainTable(
  "transfer_event", // SQL table name
  (t) => ({ // Column definitions
    id: t.text().primaryKey(),
    from: t.hex().notNull(),
    to: t.hex().notNull(),
    value: t.bigint().notNull(),
  }),
  (table) => ({  // Constraints & indexes
    fromIdx: index().on(table.from),
  })
);
Column types
The schema definition API supports most PostgreSQL data types. Here's a quick reference for the most commonly used data types. For a complete list, see the Drizzle documentation.

Name	Description	TypeScript type	SQL data type
text	UTF‐8 character sequence	string	TEXT
integer	Signed 4‐byte integer	number	INTEGER
real	Signed 4-byte floating‐point value	number	REAL
boolean	true or false	boolean	BOOLEAN
timestamp	Date and time value (no time zone)	Date	TIMESTAMP
json	JSON object	any or custom	JSON
bigint	Large integer (holds uint256 and int256)	bigint	NUMERIC(78,0)
hex	UTF‐8 character sequence with 0x prefix	0x${string}	TEXT
bytes	Byte array	Uint8Array	bytea
Column modifiers
Column modifiers can be chained after column type definitions.

Modifier	Description
.primaryKey()	Marks column as the table's primary key
.notNull()	Marks column as NOT NULL
.array()	Marks column as an array type
.default(value)	Sets a default value for column
.$default(() => value)	Sets a dynamic default via function
.$type<T>()	Annotates column with a custom TypeScript type
Constraints
Primary key
Every table must have exactly one primary key defined using either the .primaryKey() column modifier or the primaryKey() function in the table constraints argument.

ponder.schema.ts

import { onchainTable, primaryKey } from "ponder";
 
// Single column primary key
export const tokens = onchainTable("tokens", (t) => ({
  id: t.bigint().primaryKey(),
}));
 
// Composite primary key
export const poolStates = onchainTable(
  "pool_states",
  (t) => ({
    poolId: t.bigint().notNull(),
    address: t.hex().notNull(),
  }),
  (table) => ({
    pk: primaryKey({ columns: [table.poolId, table.address] }),
  })
);
Indexes
Create indexes using the index() function in the constraints & indexes argument. The indexing engine creates indexes after historical indexing completes, just before the app becomes healthy.

ponder.schema.ts

import { onchainTable, index } from "ponder";
 
export const persons = onchainTable(
  "persons",
  (t) => ({
    id: t.text().primaryKey(),
    name: t.text(),
  }),
  (table) => ({
    nameIdx: index().on(table.name),
  })
);
onchainEnum
The onchainEnum function accepts two positional arguments. It returns a function that can be used as a column type.

Argument	Type	Description
name	string	The SQL enum name. Use snake_case.
values	string[]	An array of strings representing the allowed values for the enum.
ponder.schema.ts

import { onchainEnum, onchainTable } from "ponder";
 
export const color = onchainEnum("color", ["ORANGE", "BLACK"]);
 
export const cats = onchainTable("cats", (t) => ({
  name: t.text().primaryKey(),
  color: color().notNull(),
}));
Like any other column types, you can use modifiers like .notNull(), .default(), and .array() with enum columns.

ponder.schema.ts

// ...
 
export const dogs = onchainTable("cats", (t) => ({
  name: t.text().primaryKey(),
  color: color().array().default([]),
}));
relations
Use the relations function to define relationships between tables.

ponder.schema.ts

import { onchainTable, relations } from "ponder";
 
export const users = onchainTable("users", (t) => ({
  id: t.text().primaryKey(),
}));
 
export const usersRelations = relations(users, ({ one }) => ({
  profile: one(profiles, {
    fields: [users.id],
    references: [profiles.userId],
  }),
}));
Relationship types
Type	Method	Description
One-to-one	one()	References single related record
One-to-many	many()	References array of related records
Many-to-many	Combination	Uses join table with two one-to-many relations
Read more in the relationships guide and the Drizzle relations documentation.

/////////////////////////////////////////////////////////////////////


Config API
The ponder.config.ts file contains contract names, addresses, and ABIs; network information like chain IDs and RPC URLs; database configuration; and general options.

File requirements
The ponder.config.ts file must default export the object returned by createConfig.

ponder.config.ts

import { createConfig } from "ponder";
import { http } from "viem";
 
export default createConfig({
  networks: { /* ... */ },
  contracts: { /* ... */ },
});
By default, ponder dev and start look for ponder.config.ts in the current working directory. Use the --config CLI option to specify a different path.

Event ordering
The ordering field specifies how events across multiple chains should be ordered. For single-chain apps, ordering has no effect.

field	type	
ordering	"omnichain" | "multichain"	Default: "omnichain". Event ordering strategy.
ponder.config.ts

import { createConfig } from "ponder";
 
export default createConfig({
  ordering: "multichain",
  networks: { /* ... */ },
  // ... more config
});
Guarantees
The omnichain and multichain ordering strategies offer different guarantees. Multichain ordering is generally faster, but will fail or produce a non-deterministic database state if your indexing logic attempts to access the same database row(s) from multiple chains.

Omnichain (default)	Multichain
Event order for any individual chain	Deterministic, by EVM execution	Deterministic, by EVM execution
Event order across chains	Deterministic, by (block timestamp, chain ID, block number)	Non-deterministic, no ordering guarantee
Realtime indexing latency	Medium-high, must wait for the slowest chain to maintain ordering guarantee	Low, each chain indexes blocks as soon as they arrive
Indexing logic constraints	None	Must avoid cross-chain writes or use commutative logic
Use cases	Bridges, cross-chain contract calls, global constraints	Same protocol deployed to multiple chains
Networks
The networks field is an object where each key is a network name containing that network's configuration. Networks are Ethereum-based blockchains like Ethereum mainnet, Goerli, or Foundry's local Anvil node.

Most Ponder apps require a paid RPC provider plan to avoid rate-limiting.

field	type	
name	string	A unique name for the blockchain. Must be unique across all networks. Provided as an object property name.
chainId	number	The chain ID for the network.
transport	viem.Transport	A Viem http, webSocket, or fallback Transport.
pollingInterval	number | undefined	Default: 1_000. Frequency (in ms) used when polling for new events on this network.
maxRequestsPerSecond	number | undefined	Default: 50. Maximum number of RPC requests per second. Can be reduced to work around rate limits.
disableCache	boolean | undefined	Default: false. Disables the RPC request cache. Use when indexing a local node like Anvil.
ponder.config.ts

import { createConfig } from "ponder";
import { http } from "viem";
 
import { BlitmapAbi } from "./abis/Blitmap";
 
export default createConfig({
  networks: {
    mainnet: {
      chainId: 1,
      transport: http(process.env.PONDER_RPC_URL_1),
    },
  },
  contracts: {
    Blitmap: {
      abi: BlitmapAbi,
      network: "mainnet",
      address: "0x8d04a8c79cEB0889Bdd12acdF3Fa9D207eD3Ff63",
      startBlock: 12439123,
    },
  },
});
Contracts
This is a low-level API reference. For an approachable overview & recipes, see the contracts & networks guide.

The contracts field is an object where each key is a contract name containing that contract's configuration. Ponder will sync & index logs or call traces according to the options you provide.

field	type	
name	string	A unique name for the smart contract. Must be unique across all contracts. Provided as an object property name.
abi	abitype.Abi	The contract ABI as an array as const. Must be asserted as constant, see ABIType documentation for details.
network	string	The name of the network this contract is deployed to. References the networks field. Also supports multiple networks.
address	0x{string} | 0x{string}[] | Factory | undefined	One or more contract addresses or factory configuration.
filter	Filter	Event filter criteria.
startBlock	number | "latest" | undefined	Default: 0. Block number or tag to start indexing. Usually set to the contract deployment block number.
endBlock	number | "latest" | undefined	Default: undefined. Block number or tag to stop indexing. If this field is specified, the contract will not be indexed in realtime. This field can be used alongside startBlock to index a specific block range.
includeTransactionReceipts	boolean | undefined	Default: false. If this field is true, transactionReceipt will be included in event.
includeCallTraces	boolean | undefined	Default: false. If this field is true, each function in the abi will be available as an indexing function event name. See the call traces guide for details.
ponder.config.ts

import { createConfig } from "ponder";
 
import { BlitmapAbi } from "./abis/Blitmap";
 
export default createConfig({
  // ... more config
  contracts: {
    Blitmap: {
      abi: BlitmapAbi,
      network: "mainnet",
      address: "0x8d04a8c79cEB0889Bdd12acdF3Fa9D207eD3Ff63",
      startBlock: 12439123,
    },
  },
});
Filter
field	type	
event	string | string[] | undefined	Default: undefined. One or more event names present in the provided ABI.
args	object | undefined	Default: undefined. An object containing indexed argument values to filter for. Only allowed if one event name was provided in event.
Read more about event filters.

Accounts
The accounts field is an object similar to contracts where each key is an account name containing that account's configuration. Accounts are used to index transactions or native transfers.

field	type	
name	string	A unique name for the smart contract. Must be unique across all contracts. Provided as an object property name.
network	string	The name of the network this contract is deployed to. References the networks field. Also supports multiple networks.
address	0x{string} | 0x{string}[] | Factory | undefined	Address or factory configuration.
startBlock	number | undefined	Default: 0. Block number to start syncing events.
endBlock	number | undefined	Default: undefined. Block number to stop syncing events. If this field is specified, the contract will not be indexed in realtime. This field can be used alongside startBlock to index a specific block range.
includeTransactionReceipts	boolean | undefined	Default: false. If this field is true, transactionReceipt will be included in event.
ponder.config.ts

import { createConfig } from "ponder";
 
export default createConfig({
  // ... more config
  accounts: {
    coinbasePrime: {
      network: "mainnet",
      address: "0xCD531Ae9EFCCE479654c4926dec5F6209531Ca7b",
      startBlock: 12111233,
    },
  },
});
Blocks
ponder.config.ts

import { createConfig } from "ponder";
 
export default createConfig({
  // ... more config
  blocks: {
    ChainlinkPriceOracle: {
      network: "mainnet",
      startBlock: 19_750_000,
      interval: 5, // every minute
    },
  },
});
factory()
The factory() function is used to specify if an address is derived from the log of another contract. Both contracts and accounts support factory() in their address field.

field	type	
address	0x{string} | 0x{string}[]	The address of the factory contract that creates instances of this contract.
event	AbiEvent	The ABI item of the event that announces the creation of a new child contract.
parameter	string	The name of the parameter within event that contains the address of the new child contract.
Read more about factory patterns.

ponder.config.ts

import { createConfig, factory } from "ponder";
 
export default createConfig({
  // ... more config
  contracts: {
    uniswapV2: {
      // ... other contract options
      address: factory({
        address: "0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f",
        event: parseAbiItem(
          "event PairCreated(address indexed token0, address indexed token1, address pair, uint256)"
        ),
        parameter: "pair",
      }),
    },
  },
});
Database
Here is the logic Ponder uses to determine which database to use:

If the database.kind option is specified, use the specified database.
If the DATABASE_URL environment variable is defined, use Postgres with that connection string.
If DATABASE_URL is not defined, use PGlite.
PGlite
field	type	
kind	"pglite"	
directory	string | undefined	Default: .ponder/pglite. Directory path to use for PGlite database files.
Example ponder.config.ts using PGlite

Postgres
field	type	
kind	"postgres"	
connectionString	string | undefined	Default: DATABASE_URL env var. Postgres database connection string.
poolConfig	PoolConfig | undefined	Default: { max: 30 }. Pool configuration passed to node-postgres.
Example ponder.config.ts using Postgres

Examples
Basic example
ponder.config.ts

import { createConfig } from "ponder";
import { http } from "viem";
 
import { ArtGobblersAbi } from "./abis/ArtGobblers";
 
export default createConfig({
  networks: {
    mainnet: {
      chainId: 1,
      transport: http(process.env.PONDER_RPC_URL_1),
    },
  },
  contracts: {
    ArtGobblers: {
      network: "mainnet",
      abi: ArtGobblersAbi,
      address: "0x60bb1e2aa1c9acafb4d34f71585d7e959f387769",
      startBlock: 15863321,
    },
  },
});
Using top-level await
ponder.config.ts

import { createConfig } from "ponder";
 
import { ArtGobblersAbi } from "./abis/ArtGobblers";
 
const startBlock = await fetch("http://...");
 
export default createConfig({
  networks: {
    mainnet: {
      chainId: 1,
      transport: http(process.env.PONDER_RPC_URL_1),
    },
  },
  contracts: {
    ArtGobblers: {
      network: "mainnet",
      abi: ArtGobblersAbi,
      address: "0x60bb1e2aa1c9acafb4d34f71585d7e959f387769",
      startBlock,
    },
  },
});
/////////////////////////////////////////////////

Utility types
To enable code reuse and maintain type safety for advanced use cases, Ponder offers utility types that are aware of your ponder.config.ts and ponder.schema.ts files.

Indexing function types
The "ponder:registry" module exports utility types that are useful for creating reusable helper functions in your indexing files.

EventNames
A union of all event names that are available from the contracts defined in ponder.config.ts.

src/helpers.ts

import { ponder, type EventNames } from "ponder:registry";
 
function helper(eventName: EventNames) {
  eventName;
  // ^? "Weth:Deposit" | "Weth:Withdraw" | "Weth:Approval | "Weth:Transfer"
}
Event
A generic type that optionally accepts an event name and returns the event object type for that event.

src/helpers.ts

import { ponder, type Event } from "ponder:registry";
 
function helper(event: Event<"Weth:Deposit">) {
  event;
  // ^? {
  //      args: { dst: `0x${string}`; wad: bigint };
  //      block: Block;
  //      event: "Deposit";
  //      transaction: Transaction;
  //      log: Log;
  //    }
}
If no event name is provided, Event is the union of all event types. This can be useful if all you need is the block, transaction, and log types which are the same for all events.

src/helpers.ts

import { ponder, type Event } from "ponder:registry";
 
function helper(event: Event) {
  event;
  // ^? { args: { dst: `0x${string}`; wad: bigint }; block: Block; event: "Deposit"; transaction: Transaction; log: Log; }
  //    | { args: { src: `0x${string}`; wad: bigint }; block: Block; event: "Withdraw"; transaction: Transaction; log: Log; }
  //    ...
}
Context
A generic type that optionally accepts an event name and returns the context object type.

src/helpers.ts

import { ponder, type Context } from "ponder:registry";
 
function helper(context: Context<"Weth:Deposit">) {
  event;
  // ^? {
  //      network: { name: "mainnet"; chainId: 1; };
  //      client: ReadonlyClient;
  //      db: { Account: DatabaseModel<{ id: `0x${string}`; balance: bigint; }> };
  //      contracts: { weth9: { abi: ...; address: "0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2" } };
  //    }
}
If no event name is provided, Context returns the union of all context types. This can be useful if all you need is the db or contracts types which are the same for all events.

IndexingFunctionArgs
A generic type that optionally accepts an event name and returns the indexing function argument type.

src/helpers.ts

import { ponder, type IndexingFunctionArgs } from "ponder:registry";
 
function helper(args: IndexingFunctionArgs<"Weth:Deposit">) {
  args;
  // ^? {
  //      event: { ... };
  //      context: { ... };
  //    }
}
Like Event and Context, IndexingFunctionArgs returns the union of all indexing function argument types if no event name is provided.

Schema
Use the Drizzle type helpers to create custom types for database records.

src/helpers.ts

import { accounts } from "ponder:schema";
 
function helper(account: typeof accounts.$inferSelect) {
  account;
  // ^? {
  //      id: bigint;
  //      balance: bigint;
  //      nickname: string;
  //      createdAt: number;
  //    }
}
Config types
The ponder package exports a utility type for each option passed to createConfig().

ContractConfig
The type of a contract in createConfig().

ponder.config.ts

import { createConfig, type ContractConfig } from "ponder";
import { Erc20Abi } from "./abis/Erc20Abi.ts";
 
const Erc20 = {
  network: "mainnet"
  abi: Erc20Abi,
  address: "0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2",
} as const satisfies ContractConfig;
 
export default createConfig({
  networks: ...,
  contracts: {
    Erc20,
  },
});
NetworkConfig
The type of a network in createConfig().

ponder.config.ts

import { createConfig, type NetworkConfig } from "ponder";
import { http } from "viem";
 
const mainnet = {
  chainId: 1,
  transport: http(process.env.PONDER_RPC_URL_1),
} as const satisfies NetworkConfig;
 
export default createConfig({
  networks: {
    mainnet,
  }
  contracts: ...,
});
BlockConfig
The type of a block source in createConfig().

ponder.config.ts

import { createconfig, type blockconfig } from "ponder";
 
const ChainlinkPriceOracle = {
  network: "mainnet",
  startBlock: 19_750_000,
  interval: 5,
} as const satisfies BlockConfig;
 
export default createConfig({
  networks: ...,
  blocks: {
    ChainlinkPriceOracle,
  },
});
DatabaseConfig
The type of a database in createConfig().

ponder.config.ts

import { createConfig, type DatabaseConfig } from "ponder";
 
const database = {
  kind: "postgres",
  connectionString: process.env.DATABASE_URL,
} as const satisfies DatabaseConfig;
 
export default createConfig({
  networks: ...,
  contracts: ...,
  database,
});

//////////////////////////////////////////

Write to the database
The purpose of indexing functions is to write application-ready data to the database. Ponder has two reorg-resistant database interfaces: the store API and raw SQL.

Store API
The store API is a SQL-like query builder optimized for EVM indexing workloads. It's less flexible than raw SQL, but is often several orders of magnitude faster.

The examples below use this ponder.schema.ts.

insert
Insert one or many rows into the database. Returns the inserted rows, including any default values that were generated.

src/index.ts

import { accounts } from "ponder:schema";
 
const row = await db.insert(accounts).values({
  address: "0x7Df1", balance: 0n
});
 
const rows = await db.insert(accounts).values([
  { address: "0x7Df2", balance: -50n },
  { address: "0x7Df3", balance: 100n },
]);
If you insert a row that violates a not null constraint, insert will reject with an error.

src/index.ts

import { tokens } from "ponder:schema";
 
const row = await db.insert(accounts).values({
  address: "0x7Df1",
});
 
// Error: Column "balance" is required but not present in the values object.
find
Find a single row by primary key. Returns the row, or null if no matching row is found.

src/index.ts

import { accounts } from "ponder:schema";
 
const row = await db.find(accounts, { address: "0x7Df1" });
If the table has a composite primary key, the second argument is an object including all the primary key values.

src/index.ts

import { allowances } from "ponder:schema";
 
const row = await db.find(allowances, { owner: "0x7Df1", spender: "0x7Df2" });
update
Update a row by primary key. Returns the updated row.

src/index.ts

import { accounts } from "ponder:schema";
 
const row = await db
  .update(accounts, { address: "0x7Df1" })
  .set({ balance: 100n });
You can also pass a function to set which receives the existing row and returns the update object.

src/index.ts

import { accounts } from "ponder:schema";
 
const row = await db
  .update(accounts, { address: "0x7Df1" })
  .set((row) => ({ balance: row.balance + 100n }));
If the target row is not found, update will reject with an error.

src/index.ts

import { tokens } from "ponder:schema";
 
const row = await db
  .update(accounts, { address: "0x7Df1" })
  .set({ balance: null });
 
// Error: No row found for address "0x7Df1".
If the new row violates a not null constraint, update will reject with an error.

src/index.ts

import { tokens } from "ponder:schema";
 
const row = await db
  .update(accounts, { address: "0x7Df1" })
  .set({ balance: null });
 
// Error: Column "balance" is required but not present in the object.
delete
Delete a row by primary key. Returns true if the row was deleted, or false if no matching row was found.

src/index.ts

import { accounts } from "ponder:schema";
 
const deleted = await db.delete(accounts, { address: "0x7Df1" });
Upsert & conflict resolution
If you insert a duplicate row that violates the table's primary key constraint, insert will reject with an error. Use onConflictDoNothing to skip the insert operation if a row with the same primary key already exists.

src/index.ts

import { accounts } from "ponder:schema";
 
const row = await db
  .insert(accounts)
  .values({ address: "0x7Df1", balance: 0n })
  .onConflictDoNothing();
Or, perform an upsert with onConflictDoUpdate.

src/index.ts

import { accounts } from "ponder:schema";
 
const row = await db
  .insert(accounts)
  .values({ address: "0x7Df1", balance: 0n, activeAt: event.block.timestamp })
  .onConflictDoUpdate({ activeAt: event.block.timestamp });
Like update, you can pass a function to onConflictDoUpdate which receives the existing row and returns the update object.

src/index.ts

import { accounts } from "ponder:schema";
 
const row = await db
  .insert(accounts)
  .values({ address: "0x7Df1", balance: 0n })
  .onConflictDoUpdate((row) => ({ balance: row.balance + 100n }));
Both onConflictDoNothing and onConflictDoUpdate also work when inserting many rows at once. The conflict resolution logic gets applied to each row individually.

src/index.ts

import { accounts } from "ponder:schema";
 
const rows = await db
  .insert(accounts)
  .values([
    { address: "0x7Df1", balance: 0n },
    { address: "0x7Df2", balance: 100n },
  ])
  .onConflictDoNothing();
How it works
EVM indexing workloads often involve a large number of small inserts and updates. To mitigate the performance penalty of many (blocking) database queries, the store API runs in-memory during historical indexing.

When the in-memory cache exceeds a certain size, the store flushes all pending data to the database using one COPY statement per table. During development, the store also flushes every 5 seconds regardless of size to ensure that the database state is reasonably up-to-date to support ad-hoc queries.

Raw SQL
Raw SQL queries are much slower than the store API. Avoid raw SQL for indexing logic that runs often.

The constraints of the store API make it difficult to implement complex business logic. In these cases, you can drop down to raw SQL.

Query builder
The db.sql object exposes the raw Drizzle PostgreSQL query builder, including the select, insert, update, and delete functions. Visit the Drizzle docs for more information and a detailed API reference.

Here's an example that uses the raw SQL update function to execute a complex bulk update query.

src/index.ts

import { ponder } from "ponder:registry";
import { accounts, tradeEvents } from "ponder:schema";
import { eq, and, gte, inArray, sql } from "drizzle-orm";
 
// Add 100 points to all accounts that submitted a trade in the last 24 hours.
ponder.on("EveryDay:block", async ({ event, context }) => {
  await db.sql
    .update(accounts)
    .set({ points: sql`${accounts.points} + 100` })
    .where(
      inArray(
        accounts.address,
        db.sql
          .select({ address: tradeEvents.from })
          .from(tradeEvents)
          .where(
            gte(tradeEvents.timestamp, event.block.timestamp - 24 * 60 * 60)
          )
      )
    );
});
Relational queries
Drizzle's relational query builder (AKA Drizzle Queries) offers a great developer experience for complex SELECT queries that join multiple tables. The db.sql.query object exposes the raw Drizzle relational query builder. Visit the Drizzle Queries docs for more details.

Here's an example that uses the relational query builder in an API function to find the 10 largest trades in the past hour joined with the account that made the trade.

src/api/index.ts

import { eq, and, gte, inArray, sql } from "drizzle-orm";
import { accounts, tradeEvents } from "ponder:schema";
 
ponder.get("/hot-trades", async (c) => {
  const trades = await c.db.query.tradeEvents.findMany({
    where: (table, { gt, gte, and }) =>
      and(
        gt(table.amount, 1_000n),
        gte(table.timestamp, Date.now() - 1000 * 60 * 60)
      ),
    limit: 10,
    with: { account: true },
  });
 
  return c.json(trades);
});


////////////////////////////////
API functions  - query the db.

API functions
API functions are user-defined TypeScript functions that handle web requests. You can use them to customize the API layer of your app with complex SQL queries, authentication, data from external sources, and more.

API functions are built on top of Hono, a fast and lightweight routing framework.

Example projects
These example apps demonstrate how to use API functions.

Basic - An ERC20 app that responds to GET requests and uses Drizzle to build custom SQL queries.
With offchain data - An app that includes data from offchain sources.
Get started
Create src/api/index.ts file
To enable API functions, create a file named src/api/index.ts with the following code. You can register API functions in any .ts file in the src/api/ directory.

src/api/index.ts

import { Hono } from "hono";
 
const app = new Hono();
 
app.get("/hello", (c) => {
  return c.text("Hello, world!");
});
 
export default app;
Send a request
Visit http://localhost:42069/hello in your browser to see the response.

Response

Hello, world!
Register GraphQL middleware
Starting from version 0.9.0, API functions are required and no GraphQL API is served by default.

To use the standard GraphQL API, register the graphql middleware exported from ponder. Read more about GraphQL in Ponder.

src/api/index.ts

import { db } from "ponder:api";
import schema from "ponder:schema";
import { Hono } from "hono";
import { graphql } from "ponder";
 
const app = new Hono();
 
app.use("/", graphql({ db, schema }));
app.use("/graphql", graphql({ db, schema }));
 
export default app;
Query the database
The API function context includes a ready-to-use Drizzle database client exported from ponder:api. To query the database, import table objects from ponder:schema and pass them to db.select() or use relational queries.

Select
Here's a simple query using the Drizzle select query builder.

src/api/index.ts

import { db } from "ponder:api";
import schema from "ponder:schema";
import { Hono } from "hono";
 
const app = new Hono();
 
app.get("/account/:address", async (c) => {
  const address = c.req.param("address");
 
  const account = await db
    .select()
    .from(schema.accounts)
    .where(eq(schema.accounts.address, address))
    .limit(1);
 
  return c.json(account);
});
 
export default app;
To build more complex queries, use join, groupBy, where, orderBy, limit, and other methods. Drizzle's filter & conditional operators (like eq, gte, and or) are re-exported by ponder. Visit the Drizzle documentation for more details.

Relational queries
Drizzle's relational query builder (AKA Drizzle Queries) offers a great developer experience for complex queries. The db.query object exposes the raw Drizzle relational query builder.

Here's an example that uses the relational query builder in an API function to find the 10 largest trades in the past hour joined with the account that made the trade. Visit the Drizzle Queries documentation for more details.

src/api/index.ts

import { db } from "ponder:api";
import { accounts, tradeEvents } from "ponder:schema";
import { Hono } from "hono";
import { eq, and, gte, inArray, sql } from "drizzle-orm";
 
const app = new Hono();
 
app.get("/hot-trades", async (c) => {
  const trades = await db.query.tradeEvents.findMany({
    where: (table, { gt, gte, and }) =>
      and(
        gt(table.amount, 1_000n),
        gte(table.timestamp, Date.now() - 1000 * 60 * 60)
      ),
    limit: 10,
    with: { account: true },
  });
 
  return c.json(trades);
});
 
export default app;
Send RPC requests
The API function context also includes a Viem client for each network defined in ponder.config.ts.

src/api/index.ts

import { publicClients, db } from "ponder:api";
import schema from "ponder:schema";
import { Hono } from "hono";
 
const app = new Hono();
 
app.get("/account/:chainId/:address", async (c) => {
  const chainId = c.req.param("chainId");
  const address = c.req.param("address");
 
  const balance = await publicClients[chainId].getBalance({ address });
 
  const account = await db.query.accounts.findFirst({
    where: eq(schema.accounts.address, address),
  });
 
  return c.json({ balance, account });
});
 
export default app;
Reserved routes
If you register API functions that conflict with these internal routes, the build will fail.

/health: Returns a 200 status code immediately after the app starts running. Read more about healthchecks.
/ready: Returns a 200 status code after the app has completed the historical backfill and is available to serve traffic. Read more about healthchecks.
/metrics: Returns Prometheus metrics. Read more about metrics.
/status: Returns indexing status object. Read more about indexing status.

////////////////////////

SQL client queries
The @ponder/client package provides an SQL client for querying a Ponder app over HTTP, with end-to-end type inference and live updates. It's an alternative to the GraphQL API.

Enable on the server
To enable client queries, register the client middleware in your API function file.

src/api/index.ts

import { db } from "ponder:api";
import schema from "ponder:schema";
import { Hono } from "hono";
import { client, graphql } from "ponder";
 
const app = new Hono();
 
app.use("/graphql", graphql({ db, schema }));
app.use("/sql/*", client({ db, schema }));
 
export default app;
Read more about how the client middleware protects against malicious queries and denial-of-service attacks.

@ponder/client
The @ponder/client package works in any JavaScript environment, including the browser, server-side scripts, and both client and server code from web frameworks like Next.js. If you're using a React framework, use the @ponder/react package instead.

Guide
Installation
Install the @ponder/client package in your client project.

shell

pnpm add @ponder/client
Create client
Create a client using the URL of your Ponder server. Import your schema into the same file using a relative import from your ponder.schema.ts file.

import { createClient } from "@ponder/client";
import * as schema from "../../ponder/ponder.schema";
 
const client = createClient("http://localhost:42069/sql", { schema });

Non-monorepo users: If your Ponder project and client project are not in the same repository, you won't be able to use a relative import. We're working on a solution for this, stay tuned.

Run a query
Use the client.db method to execute a SELECT statement using Drizzle. The query builder is fully type-safe to provide static query validation and inferred result types.

import { createClient } from "@ponder/client";
import * as schema from "../../ponder/ponder.schema";
 
const client = createClient("https://.../sql", { schema });
 
const result = await client.db.select().from(schema.account).limit(10);

API Reference
client.db
This method uses server side query validation and a database session with strict query limits. It provides a Drizzle query builder, similar to API functions.

import { createClient } from "@ponder/client";
import * as schema from "../../ponder/ponder.schema";
 
const client = createClient("https://.../sql", { schema });
 
const result = await client.db.select().from(schema.account).limit(10);

client.live
Subscribe to live updates.

This method intiates a HTTP connection with the server using server-sent events (SSE). The server notifies the client whenever a new block gets indexed. If a query result is no longer valid, the client immediately refetches it to receive the latest result. This approach achieves low-latency updates with minimal network traffic.

To avoid browser quotas, each client instance uses at most one SSE connection at a time.

import { createClient } from "@ponder/client";
import * as schema from "../../ponder/ponder.schema";
 
const client = createClient("https://.../sql", { schema });
 
const { unsubscribe } = client.live(
  (db) => db.select().from(schema.account),
  (result) => {
    // ...
  },
  (error) => {
    // ...
  }
);

client.getStatus
Get the indexing progress of each chain.

import { createClient } from "@ponder/client";
import * as schema from "../../ponder/ponder.schema";
 
const client = createClient("https://.../sql", { schema });
 
const status = await client.getStatus();

Query from React
The @ponder/react package provides React hooks for subscribing to live updates from your database, powered by @ponder/client. This package wraps TanStack Query, a popular library for managing async state in React.

components/Deposits.tsx

import { usePonderQuery } from "@ponder/react";
 
export function Deposits() {
  const { data, isError, isPending } = usePonderQuery({
    queryFn: (db) => db.select().from(schema.depositEvent).limit(10),
  });
 
  // ...
}
Guide
Installation
Install @ponder/react and peer dependencies in your React project.

shell

pnpm add @ponder/react @ponder/client @tanstack/react-query
Create client
Create a client object using the URL of your Ponder server. Import your schema into the same file using a relative import from your ponder.schema.ts file.

lib/ponder.ts

import { createClient } from "@ponder/client";
import * as schema from "../../ponder/ponder.schema";
 
const client = createClient("http://localhost:42069/sql", { schema });
 
export { client, schema };
Non-monorepo users: If your Ponder project and client project are not in the same repository, you won't be able to use a relative import. We're working on a solution for this, stay tuned.

Wrap app in provider
Wrap your app with the PonderProvider and include the client object you just created.

app.tsx

import { PonderProvider } from "@ponder/react";
import { client } from "./lib/ponder";
 
function App() {
  return (
    <PonderProvider client={client}>
      {/** ... */}
    </PonderProvider>
  );
}
Setup TanStack Query
Inside the PonderProvider, wrap your app with a TanStack Query Provider. Read more about setting up TanStack Query.

app.tsx

import { QueryClient, QueryClientProvider } from "@tanstack/react-query";
import { PonderProvider } from "@ponder/react";
import { client } from "./lib/ponder";
 
const queryClient = new QueryClient();
 
function App() {
  return (
    <PonderProvider client={client}>
      <QueryClientProvider client={queryClient}>
        {/** ... */}
      </QueryClientProvider>
    </PonderProvider>
  );
}
Use the hook
In a React client component, use the usePonderQuery hook to fetch data. The hook returns an ordinary TanStack Query result object.

components/Deposits.tsx

import { usePonderQuery } from "@ponder/react";
import { schema } from "../lib/ponder";
 
export function Deposits() {
  const { data, isError, isPending } = usePonderQuery({
    queryFn: (db) =>
      db.select()
        .from(schema.depositEvent)
        .orderBy(schema.depositEvent.timestamp)
        .limit(10),
  });
 
  if (isPending) return <div>Loading deposits</div>;
  if (isError) return <div>Error fetching deposits</div>;
  return <div>Deposits: {data}</div>;
}
API Reference
usePonderQuery
Hook for querying a Ponder app with live updates.

import { usePonderQuery } from "@ponder/react";
 
const { data } = usePonderQuery({
  queryFn: (db) =>
    db
      .select()
      .from(schema.depositEvent)
      .orderBy(schema.depositEvent.timestamp)
      .limit(10),
});

usePonderStatus
Hook for querying the indexing status of each chain.

import { usePonderStatus } from "@ponder/react";
 
const { data } = usePonderStatus();

getPonderQueryOptions
Helper function to build the Tanstack queryFn and queryKey for a SQL query.

Use getPonderQueryOptions in a Next.js app to prefetch data on the server. Read more.

import { getPonderQueryOptions } from "@ponder/react";
 
const { queryFn, queryKey } = getPonderQueryOptions(client, (db) =>
  db.select().from(schema.depositEvent).limit(10)
);

PonderProvider
React Context Provider for @ponder/react.

import { PonderProvider } from "@ponder/react";
import { client } from "./lib/ponder";
 
function App() {
  return <PonderProvider client={client}>{/** ... */}</PonderProvider>;
}

Example projects
These example apps demonstrate how to use @ponder/client and @ponder/react.

Basic
Next.js
Security
Here are the measures taken by the client middleware to prevent malicious queries & denial-of-service attacks.

Read-only: Each query statement runs in an READ ONLY transaction using autocommit.

Query validator: Each query is parsed using libpg_query and must pass the following checks.

The root of the AST must be a SELECT statement. Queries containing multiple statements are rejected.
The query must only contain allowlisted AST nodes and built-in SQL functions. For example, SELECT, WHERE, and max() are allowed, but DELETE, SET, and pg_advisory_lock() are not. Read more.
The query must not contain references to objects in schemas other than the current schema. Read more.
Resource limits: The database session uses the following resource limit settings.

SET work_mem = '512MB';
SET statement_timeout = '500ms';
SET lock_timeout = '500ms';

Together, these measures aim to achieve a similar level of risk as the GraphQL API.
///////

Direct SQL queries against PGlite are possible, but the methods described here do not work out of the box.

psql
You can also use psql, a terminal-based Postgres front-end, to query the database from the command line.

Connection string
Connect using the same connection string that your Ponder app uses.

shell

psql 'postgresql://username:password@localhost:5432/your_database'
Display tables
Use the \dt command to list all tables in the public schema. If you are using a schema other than public, include the pattern.

psql

\dt
psql

\dt my_schema.*
The reorg tables are used by Ponder internally during reorg reconciliation, and the _ponder_meta table is used to store metadata about the database state.

psql (result)

                    List of relations
 Schema | Name                        | Type  | Owner
--------+-----------------------------+-------+----------
 public | accounts                    | table | username
 public | transfer_events             | table | username
 public | _ponder_meta                | table | username
 public | _ponder_status              | table | username
 public | _reorg__accounts            | table | username
 public | _reorg__transfer_events     | table | username
(5 rows)
Select rows
Select a few rows from the accounts table.

psql

SELECT * FROM accounts LIMIT 5;
psql (result)

                  address                   |         balance         |
--------------------------------------------+-------------------------+
 0xf73fe15cfb88ea3c7f301f16ade3c02564aca407 | 10000000000000000000000 |
 0xb0659bc97ed61b37d6b140f3e12a41d471781714 | 20000000000000000000000 |
 0x52932f5b2767d917c3134140168f2176c94e8b2c | 10000000000000000000000 |
 0xfb7ca75b3ce099120602b5ab7104cff030ee43f8 |                       0 |
 0x9ccc6c5a9d25429f55ad9af6363c1c4f16b179ad |  7000000000000000000000 |
(5 rows)
Aggregate data
Find the total number of transfers sent to each account.

psql

SELECT "to", COUNT(*) AS transfer_count
  FROM transfer_events
  GROUP BY "to"
  ORDER BY transfer_count DESC
  LIMIT 5;
psql (result)

                     to                     | transfer_count
--------------------------------------------+----------------
 0x5d752f322befb038991579972e912b02f61a3dda |           2342
 0x1337f7970e8399ccbc625647fce58a9dada5aa66 |            313
 0x9726041047644626468922598128349778349982 |            306
 0x27239549dd40e1d60f5b80b0c4196923745b1fd2 |            256
 0x450638daf0caedbdd9f8cb4a41fa1b24788b123e |            238
(5 rows)
Drizzle
As of 0.8, the onchainTable objects are not automatically aware of the database schema that your instance is using. To get this working, you'll need to specify the schema using setDatabaseSchema().

The onchainTable objects exported by ponder.schema.ts are valid Drizzle table objects. You can import them from TypeScript files outside the Ponder src/ directory and use them with the Drizzle query builder.

Here's a script that creates a Drizzle client and runs a query against the Ponder tables in the specified schema. Be sure to connect to the database using the same DATABASE_URL as the Ponder app.

query.ts

import { setDatabaseSchema } from "@ponder/client";
import { drizzle } from "drizzle-orm/node-postgres";
import * as _schema from "../../ponder/ponder.schema";
 
const schema = setDatabaseSchema(_schema, "my_schema");
 
const db = drizzle(process.env.DATABASE_URL, { schema, casing: "snake_case" });
 
// Select
const oldAccounts = await db
  .select()
  .from(schema.accounts)
  .orderBy(asc(schema.accounts.createdAt))
  .limit(100);
 
// Query
const whalesWithTransfers = await db.query.accounts.findMany({
  where: (accounts, { eq }) => eq(accounts.balance, 1_000_000n),
  with: { transferEvents: true },
});

////// 
using version over 0.9.0

