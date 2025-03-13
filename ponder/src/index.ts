import { ponder } from "ponder:registry";
import { ABIs, deployments } from "../abis/abi";

// Import the handlers from respective files
import * as WillWeHandlers from './WillWe';
import * as ExecutionHandlers from './Execution';
import * as MembranesHandlers from './Membrane';

// Import syncFoundry to ensure it runs (import only, the function runs on import)
import './syncFoundry';

// For OP Sepolia (chainId 11155420)
ponder.on("WillWe_11155420:NewRootNode", WillWeHandlers.handleNewRootNode);
ponder.on("WillWe_11155420:NewNode", WillWeHandlers.handleNewNode);
ponder.on("WillWe_11155420:MembershipMinted", WillWeHandlers.handleMembershipMinted);
ponder.on("WillWe_11155420:TransferSingle", WillWeHandlers.handleTransferSingle);
ponder.on("WillWe_11155420:TransferBatch", WillWeHandlers.handleTransferBatch);
ponder.on("WillWe_11155420:UserNodeSignal", WillWeHandlers.handleUserNodeSignal);
ponder.on("WillWe_11155420:ConfigSignal", WillWeHandlers.handleConfigSignal);
ponder.on("WillWe_11155420:CreatedEndpoint", WillWeHandlers.handleCreatedEndpoint);

// Execution handlers for OP Sepolia
ponder.on("Execution_11155420:NewMovementCreated", ExecutionHandlers.handleNewMovementCreated);
ponder.on("Execution_11155420:QueueExecuted", ExecutionHandlers.handleQueueExecuted);
ponder.on("Execution_11155420:NewSignaturesSubmitted", ExecutionHandlers.handleNewSignaturesSubmitted);
ponder.on("Execution_11155420:SignatureRemoved", ExecutionHandlers.handleSignatureRemoved);
ponder.on("Execution_11155420:WillWeSet", ExecutionHandlers.handleWillWeSet);

// Membrane handlers for OP Sepolia
ponder.on("Membrane_11155420:MembraneCreated", MembranesHandlers.handleMembraneCreated);


// Log which events are being indexed
console.log("Registering event handlers for WillWe and Execution contracts on OP Sepolia");