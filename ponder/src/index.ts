import { ponder } from "ponder:registry";
import { ABIs, deployments } from "../abis/abi";

// Import the handlers from respective files
import * as WillWeHandlers from './WillWe';
import * as ExecutionHandlers from './Execution';
import * as MembranesHandlers from './Membrane';
import * as WillHandlers from './Will';

import './syncFoundry';





// For Base Mainnet (chainId 8453)
ponder.on("WillWe-8453:NewRootNode", WillWeHandlers.handleNewRootNode);
ponder.on("WillWe-8453:NewNode", WillWeHandlers.handleNewNode);
ponder.on("WillWe-8453:MembershipMinted", WillWeHandlers.handleMembershipMinted);
ponder.on("WillWe-8453:UserNodeSignal", WillWeHandlers.handleUserNodeSignal);
ponder.on("WillWe-8453:CreatedEndpoint", WillWeHandlers.handleCreatedEndpoint);
ponder.on("WillWe-8453:MembraneChanged", WillWeHandlers.handleMembraneChanged);
ponder.on("WillWe-8453:InflationRateChanged", WillWeHandlers.handleInflationRateChanged);
ponder.on("WillWe-8453:SharesGenerated", WillWeHandlers.handleSharesGenerated);
ponder.on("WillWe-8453:Minted", WillWeHandlers.handleMinted);
ponder.on("WillWe-8453:Burned", WillWeHandlers.handleBurned);
ponder.on("WillWe-8453:MembraneSignal", WillWeHandlers.handleMembraneSignal);
ponder.on("WillWe-8453:InflationSignal", WillWeHandlers.handleInflationSignal);

// Execution handlers for Base Mainnet
ponder.on("Execution-8453:NewMovementCreated", ExecutionHandlers.handleNewMovementCreated);
ponder.on("Execution-8453:QueueExecuted", ExecutionHandlers.handleQueueExecuted);
ponder.on("Execution-8453:NewSignaturesSubmitted", ExecutionHandlers.handleNewSignaturesSubmitted);
ponder.on("Execution-8453:SignatureRemoved", ExecutionHandlers.handleSignatureRemoved);
ponder.on("Execution-8453:WillWeSet", ExecutionHandlers.handleWillWeSet);

// Membrane handlers for Base Mainnet
ponder.on("Membranes-8453:MembraneCreated", MembranesHandlers.handleMembraneCreated);

// Log which events are being indexed
console.log("Registering event handlers for WillWe and Execution contracts on OP Sepolia and Base Mainnet");