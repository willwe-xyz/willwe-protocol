import { createConfig } from "ponder";
import { http, Abi } from "viem";
import * as viemChains from "viem/chains";
import { ABIs, deployments } from "./abis/abi";
import "./src/syncFoundry";

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
  1: process.env.MAINNET_RPC_URL || "https://eth.llamarpc.com",
  // 10: process.env.OPTIMISM_RPC_URL || "https://optimism.llamarpc.com",
  // 11155420: process.env.OPTIMISM_SEPOLIA_RPC_URL || "https://sepolia.optimism.io", // OP Sepolia
  8453: process.env.BASE_RPC_URL || "https://base.llamarpc.com",
  // 84532: process.env.BASE_SEPOLIA_RPC_URL || "https://sepolia.base.org", // Base Sepolia
  // 167009: process.env.TAIKO_HEKLA_RPC_URL || "https://rpc.katla.taiko.xyz", // Taiko Katla 
};

// Create a safe empty ABI to use as a fallback
const emptyAbi: Abi = [];
export const startBlock = 27073969;

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
      if ('WillWe' in deployments && deployments.WillWe[chainIdStr]) {
        if (!ABIs.WillWe) {
          console.warn(`Missing ABI for WillWe on chain ${chainId}, skipping`);
          continue;
        }
        contracts[`WillWe-${chainId}`] = {
          abi: ABIs.WillWe as Abi,
          address: deployments.WillWe[chainIdStr],
          network: networkName,
          startBlock: startBlock
        };
      }
      
      // Membranes contract
      if ('Membranes' in deployments && deployments.Membranes?.[chainIdStr]) {
        if (!ABIs.Membranes) {
          console.warn(`Missing ABI for Membranes on chain ${chainId}, skipping`);
          continue;
        }
        contracts[`Membranes-${chainId}`] = {
          abi: ABIs.Membranes as Abi,
          address: deployments.Membranes[chainIdStr],
          network: networkName,
          startBlock: startBlock
        };
      }
      
      // Execution contract
      if ('Execution' in deployments && deployments.Execution?.[chainIdStr]) {
        if (!ABIs.Execution) {
          console.warn(`Missing ABI for Execution on chain ${chainId}, skipping`);
          continue;
        }
        contracts[`Execution-${chainId}`] = {
          abi: ABIs.Execution as Abi,
          address: deployments.Execution[chainIdStr],
          network: networkName,
          startBlock: startBlock
        };
      }
      
      // Will contract
      if ('Will' in deployments && deployments.Will?.[chainIdStr]) {
        if (!ABIs.Will) {
          console.warn(`Missing ABI for Will on chain ${chainId}, skipping`);
          continue;
        }
        contracts[`Will-${chainId}`] = {
          abi: ABIs.Will as Abi,
          address: deployments.Will[chainIdStr],
          network: networkName,
          startBlock: startBlock
        };
      }
    }
  }
  
  // Log the registered contracts for debugging
  console.log("Registered contracts:", Object.keys(contracts));
  
  return contracts;
}

// Create the Ponder configuration
export default createConfig({
  networks,
  contracts: getAllContracts(),
  database: {
    kind: "postgres",
    connectionString: process.env.PONDER_DATABASE_URL || "postgres://postgres:postgres@localhost:5432/ponder",
    schema: "willwedfbfbsfsddsfsdas"
  },
});


