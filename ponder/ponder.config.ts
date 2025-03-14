import { createConfig } from "ponder";
import { http, Abi } from "viem";
import * as viemChains from "viem/chains";
import { ABIs, deployments } from "./abis/abi";

// Collection of all chains that could be supported
export const supportedChains: viemChains.Chain[] = [
  viemChains.mainnet,
  viemChains.sepolia,
  viemChains.optimism,
  viemChains.optimismSepolia,
  viemChains.arbitrum,
  viemChains.arbitrumSepolia,
  viemChains.base,
  viemChains.baseSepolia,
  viemChains.polygon,
  viemChains.zora,
  viemChains.mode,
  viemChains.gnosis,
  viemChains.ink,
  viemChains.soneium,
  viemChains.avalanche,
  viemChains.mantle,
  viemChains.zksync,
  viemChains.scroll,
  viemChains.taiko,
];

// Default RPC URLs for development environment
const defaultRpcUrls: Record<number, string> = {
  1: "https://eth.llamarpc.com",
  10: "https://optimism.llamarpc.com",
  11155420: "https://sepolia.optimism.io", // OP Sepolia
  8453: "https://base.llamarpc.com",
  84532: "https://sepolia.base.org", // Base Sepolia
  167009: "https://rpc.katla.taiko.xyz", // Taiko Katla 
};

// Create a safe empty ABI to use as a fallback
const emptyAbi: Abi = [];
export const startBlock = 25050000;

// Get all available chainIds from deployments
const availableChainIds = Object.keys(Object.values(deployments)[0] || {}).map(Number);

// Generate networks configuration for available chains
const networks: Record<string, { chainId: number; transport: ReturnType<typeof http> }> = {};
for (const chainId of availableChainIds) {
  // Find the corresponding chain in supportedChains
  const chain = supportedChains.find(c => c.id === chainId);
  
  if (chain) {
    const rpcUrl = process.env[`PONDER_RPC_URL_${chainId}`] || defaultRpcUrls[chainId] || "";
    if (!rpcUrl) {
      console.warn(`No RPC URL found for chain ID ${chainId} (${chain.name}), skipping`);
      continue;
    }
    
    networks[chain.name] = {
      chainId,
      transport: http(rpcUrl),
    };
  }
}

// Get contracts for all networks that have deployments
export const getAllContracts = () => {
  const contracts: Record<string, {
    abi: Abi;
    address: string;
    network: string;
    startBlock: number;
  }> = {};
  
  // For each chainId that has deployments
  for (const chainIdStr of Object.keys(deployments.WillWe || {})) {
    const chainId = Number(chainIdStr);
    // Find the corresponding chain in supportedChains
    const chain = supportedChains.find(c => c.id === chainId);
    if (!deployments.WillWe || !deployments.WillWe[chainIdStr]) continue;

    if (chain) {
      const networkName = chain.name;
      
      // WillWe contract
      if ('WillWe' in deployments && deployments.WillWe[chainIdStr] && ABIs.WillWe) {
        contracts[`WillWe_${chainId}`] = {
          abi: ABIs.WillWe as Abi,
          address: deployments.WillWe[chainIdStr],
          network: networkName,
          startBlock: startBlock
        };
      }
      
      // Membranes contract
      if ('Membranes' in deployments && deployments.Membranes?.[chainIdStr] && ABIs.Membranes) {
        contracts[`Membrane_${chainId}`] = {
          abi: ABIs.Membranes as Abi,
          address: deployments.Membranes[chainIdStr],
          network: networkName,
          startBlock: startBlock
        };
      }
      
      // Execution contract
      if ('Execution' in deployments && deployments.Execution?.[chainIdStr] && ABIs.Execution) {
        contracts[`Execution_${chainId}`] = {
          abi: ABIs.Execution as Abi,
          address: deployments.Execution[chainIdStr],
          network: networkName,
          startBlock: startBlock
        };
      }
      
      // Will contract
      if ('Will' in deployments && deployments.Will?.[chainIdStr] && ABIs.Will) {
        contracts[`Will_${chainId}`] = {
          abi: ABIs.Will as Abi,
          address: deployments.Will[chainIdStr],
          network: networkName,
          startBlock: startBlock
        };
      }
    }

    console.log(`Contracts for chain ${chainId} (${chain?.name}):`, contracts);

  }
  
  return contracts;
}

// Import our syncFoundry module to ensure it runs during server startup
import "./src/syncFoundry";

console.log("Available contracts:", Object.keys(getAllContracts()));

// Create the Ponder configuration
export default createConfig({
  networks,
  contracts: getAllContracts(),
  database: {
    kind: "postgres",
    connectionString: process.env.DATABASE_URL || "postgres://postgres:postgres@localhost:5432/ponder",
  },
});


