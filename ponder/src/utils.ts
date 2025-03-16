import {
  Chain,
  mainnet,
  sepolia,
  optimism,
  optimismSepolia,
  arbitrum,
  arbitrumSepolia,
  base,
  baseSepolia,
  polygon,
  polygonMumbai
} from "viem/chains";

// Define all the chains we want to support
const supportedChains: Chain[] = [
  mainnet,
  sepolia,
  optimism,
  optimismSepolia,
  arbitrum,
  arbitrumSepolia,
  base,
  baseSepolia,
  polygon,
  polygonMumbai,
];

// Add a local chain
const localChain: Chain = {
  id: 31337,
  name: "Local",
  nativeCurrency: { name: "Ether", symbol: "ETH", decimals: 18 },
  rpcUrls: {
    default: { http: ["http://localhost:8545"] },
    public: { http: ["http://localhost:8545"] },
  }
};

supportedChains.push(localChain);

/**
 * Finds a chain by its ID from viem's chain objects
 * @param chainId The chain ID to search for
 * @returns The matching Chain object or undefined if not found
 */
export function findChainById(chainId: number): Chain | undefined {
  return supportedChains.find(chain => chain.id === chainId);
}

/**
 * Gets the network name from a chainId
 * @param chainId The chain ID
 * @returns The network name (lowercase) or "unknown" if not found
 */
export function getNetworkNameFromChainId(chainId: number): string {
  const chain = findChainById(chainId);
  return chain ? chain.name.toLowerCase() : "unknown";
}

/**
 * Infers the network from chainId for ponder schema compatibility
 * @param chainId The chain ID
 * @returns A normalized network name suitable for the schema
 */
export function inferNetworkFromChainId(chainId: number): string {
  const chain = findChainById(chainId);
  if (!chain) return "unknown";
  
  // Convert chain name to lowercase and remove spaces
  const networkName = chain.name.toLowerCase().replace(/\s+/g, '');
  
  return networkName || 'unknown';
}

/**
 * Creates a network-prefixed ID
 * @param network The network name
 * @param id The base ID to prefix
 * @returns A network-prefixed ID string
 */
export function createNetworkId(network: string, id: string): string {
  return `${network}-${id}`;
}

/**
 * Get network information for database storage
 * @param chainIdOrName The chain ID or network name
 * @returns An object with network name and ID
 */
export function getNetworkInfo(chainIdOrName: number | string): { networkName: string, networkId: number } {
  let chain: Chain | undefined;
  
  if (typeof chainIdOrName === 'number') {
    chain = findChainById(chainIdOrName);
  } else {
    const normalizedName = chainIdOrName.toLowerCase();
    chain = supportedChains.find(c => c.name.toLowerCase() === normalizedName);
  }
  
  if (!chain) {
    // Default to optimism sepolia if not found
    chain = optimismSepolia;
  }
  
  return {
    networkName: chain.name.toLowerCase(),
    networkId: chain.id
  };
}