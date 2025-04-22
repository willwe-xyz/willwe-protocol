import { readFileSync, existsSync, writeFileSync, readdirSync } from 'fs';
import { join } from 'path';
import { Abi } from 'viem';

// Type definitions
type Deployments = { [key: string]: { [key: string]: string } };
type ABIKP = { [key: string]: Abi };

/**
 * Reads current deployments from abi.ts
 * @returns Current deployments object or empty object if not found
 */
function getCurrentDeployments(): Deployments {
  try {
    const abiPath = join(process.cwd(), 'abis', 'abi.ts');
    if (!existsSync(abiPath)) return {};
    
    const content = readFileSync(abiPath, 'utf8');
    const deploymentsMatch = content.match(/export const deployments\s*=\s*(\{[\s\S]*?\});/);
    
    if (deploymentsMatch && deploymentsMatch[1]) {
      // eslint-disable-next-line no-eval
      return eval(`(${deploymentsMatch[1]})`);
    }
  } catch (err) {
    console.warn(`Error reading current deployments: ${err}`);
  }
  
  return {};
}

/**
 * Reads deployment information from Foundry broadcast files
 * @returns Object with contract deployments by chain
 */
export function readFoundryDeployments(): Deployments {
  // Start with current deployments to maintain existing addresses
  const currentDeployments = getCurrentDeployments();
  const deployments: Deployments = {
    "Will": { ...(currentDeployments.Will || {}) },
    "Membranes": { ...(currentDeployments.Membranes || {}) },
    "Execution": { ...(currentDeployments.Execution || {}) },
    "WillWe": { ...(currentDeployments.WillWe || {}) }
  };
  
  const broadcastDir = join(process.cwd(), '..', 'broadcast');
  
  // Get all deployment files from broadcast directory
  try {
    // Check broadcast directory for latest deployments
    if (existsSync(broadcastDir)) {
      // Process script deployment directories like WillWeDeploy2.s.sol/11155420/run-latest.json
      const broadcastEntries = readdirSync(broadcastDir, { withFileTypes: true })
        .filter(entry => entry.isDirectory() && entry.name.endsWith('.s.sol'))
        .map(entry => entry.name);
      
      // Contract name mapping for script deployments
      const contractNameToDeployKey = {
        'WillWe': 'WillWe',
        'Fun': 'WillWe', // Map Fun to WillWe for consistency
        'Execution': 'Execution',
        'Membranes': 'Membranes',
        'Membrane': 'Membranes',
        'Will': 'Will',
        'RVI': 'Will',
        'RootValuationImplementation': 'Will'
      };
      
      // Process each script directory
      for (const scriptDir of broadcastEntries) {
        const scriptBroadcastDir = join(broadcastDir, scriptDir);
        
        try {
          const chainEntries = readdirSync(scriptBroadcastDir, { withFileTypes: true })
            .filter(entry => entry.isDirectory())
            .map(entry => entry.name);
          
          for (const chain of chainEntries) {
            const runJsonPath = join(scriptBroadcastDir, chain, 'run-latest.json');
            
            if (existsSync(runJsonPath)) {
              try {
                const runJson = JSON.parse(readFileSync(runJsonPath, 'utf8'));
                
                if (runJson.transactions) {
                  for (const tx of runJson.transactions) {
                    // Find contract deployments
                    if (tx.contractName && tx.contractAddress) {
                      const deployKey = contractNameToDeployKey[tx.contractName as keyof typeof contractNameToDeployKey];
                      
                      if (deployKey && deployments[deployKey]) {
                        // Only update if this is a new deployment (no address exists) or newer in timestamp
                        deployments[deployKey][chain] = tx.contractAddress.toLowerCase();
                      }
                    }
                  }
                }
              } catch (err) {
                console.warn(`Error parsing ${runJsonPath}: ${err}`);
              }
            }
          }
        } catch (err) {
          console.warn(`Error reading directory ${scriptBroadcastDir}: ${err}`);
        }
      }
      
      // Also process direct deployment files
      const deployFiles = {
        'Will.json': 'Will',
        'Membranes.json': 'Membranes',
        'Execution.json': 'Execution',
        'WillWe.json': 'WillWe'
      };
      
      for (const [fileName, deployKey] of Object.entries(deployFiles)) {
        const filePath = join(broadcastDir, fileName);
        if (!existsSync(filePath)) continue;
        
        try {
          const fileContent = readFileSync(filePath, 'utf8');
          const deployData = JSON.parse(fileContent);
          
          if (deployData && deployData.transactions) {
            for (const tx of deployData.transactions) {
              if (tx.chainId && tx.contractAddress && deployKey && deployments[deployKey]) {
                deployments[deployKey][tx.chainId.toString()] = tx.contractAddress.toLowerCase();
              }
            }
          }
        } catch (err) {
          console.warn(`Error parsing ${fileName}: ${err}`);
        }
      }
    }
  } catch (err) {
    console.warn(`Error reading broadcast directory: ${err}`);
  }

  // // Manual deployment overrides for debugging
  // // Add the WillWe contract address for OP Sepolia
  // deployments.WillWe["11155420"] = "0xD31ED23C4D4E53AB87Ec4a4d8dFc42e2b4df4920";

  return deployments;
}

/**
 * Reads ABIs from Foundry artifacts
 * @returns Object with contract ABIs
 */
export function readFoundryABIs(): ABIKP {
  const abis: ABIKP = {};
  
  // Define where to find each contract's ABI
  const contractToSolFile = {
    'Will': 'Will.sol',
    'Membranes': 'Membranes.sol',
    'Execution': 'Execution.sol',
    'WillWe': 'WillWe.sol'  // Primary location
  };
  
  // Alternative locations for ABIs
  const alternativeLocations: { [key: string]: string[] } = {
    'WillWe': ['Fun.sol/Fun.json'] // Now Fun contract is used as WillWe
  };
  
  const outDir = join(process.cwd(), '..', 'out');
  
  // For each contract we need to get the ABI
  for (const [contractName, solFile] of Object.entries(contractToSolFile)) {
    // Standard path
    let abiPath = join(outDir, solFile, `${contractName}.json`);
    let abiFound = false;
    
    // Try standard path first
    if (existsSync(abiPath)) {
      try {
        const fileContent = readFileSync(abiPath, 'utf8');
        const artifactData = JSON.parse(fileContent);
        
        if (artifactData && artifactData.abi) {
          abis[contractName] = artifactData.abi;
          console.log(`Found ABI for ${contractName} at ${abiPath}`);
          abiFound = true;
        }
      } catch (err) {
        console.warn(`Error reading ABI for ${contractName}: ${err}`);
      }
    }
    
    // If not found yet, try alternatives
    if (!abiFound && alternativeLocations[contractName]) {
      for (const altPath of alternativeLocations[contractName]) {
        const fullAltPath = join(outDir, altPath);
        if (existsSync(fullAltPath)) {
          try {
            const fileContent = readFileSync(fullAltPath, 'utf8');
            const artifactData = JSON.parse(fileContent);
            
            if (artifactData && artifactData.abi) {
              abis[contractName] = artifactData.abi;
              console.log(`Found ABI for ${contractName} at ${fullAltPath}`);
              abiFound = true;
              break;
            }
          } catch (err) {
            console.warn(`Error reading alternative ABI for ${contractName}: ${err}`);
          }
        }
      }
    }
    
    // If we still don't have the ABI, check if we have a JSON file in the abis directory
    if (!abiFound) {
      const localAbiPath = join(process.cwd(), 'abis', `${contractName}.json`);
      if (existsSync(localAbiPath)) {
        try {
          const fileContent = readFileSync(localAbiPath, 'utf8');
          const artifactData = JSON.parse(fileContent);
          
          if (artifactData && artifactData.abi) {
            abis[contractName] = artifactData.abi;
            console.log(`Found ABI for ${contractName} at ${localAbiPath}`);
            abiFound = true;
          }
        } catch (err) {
          console.warn(`Error reading local ABI for ${contractName}: ${err}`);
        }
      }
    }
    
    if (!abiFound) {
      console.warn(`No ABI file found for ${contractName}`);
    }
  }
  
  // Add standard IERC20 interface ABI
  abis['IERC20'] = [
    {
      "constant": true,
      "inputs": [],
      "name": "name",
      "outputs": [{ "name": "", "type": "string" }],
      "payable": false,
      "stateMutability": "view",
      "type": "function"
    },
    {
      "constant": false,
      "inputs": [{ "name": "_spender", "type": "address" }, { "name": "_value", "type": "uint256" }],
      "name": "approve",
      "outputs": [{ "name": "", "type": "bool" }],
      "payable": false,
      "stateMutability": "nonpayable",
      "type": "function"
    },
    {
      "constant": true,
      "inputs": [],
      "name": "totalSupply",
      "outputs": [{ "name": "", "type": "uint256" }],
      "payable": false,
      "stateMutability": "view",
      "type": "function"
    },
    {
      "constant": false,
      "inputs": [
        { "name": "_from", "type": "address" },
        { "name": "_to", "type": "address" },
        { "name": "_value", "type": "uint256" }
      ],
      "name": "transferFrom",
      "outputs": [{ "name": "", "type": "bool" }],
      "payable": false,
      "stateMutability": "nonpayable",
      "type": "function"
    },
    {
      "constant": true,
      "inputs": [],
      "name": "decimals",
      "outputs": [{ "name": "", "type": "uint8" }],
      "payable": false,
      "stateMutability": "view",
      "type": "function"
    },
    {
      "constant": true,
      "inputs": [{ "name": "_owner", "type": "address" }],
      "name": "balanceOf",
      "outputs": [{ "name": "balance", "type": "uint256" }],
      "payable": false,
      "stateMutability": "view",
      "type": "function"
    },
    {
      "constant": true,
      "inputs": [],
      "name": "symbol",
      "outputs": [{ "name": "", "type": "string" }],
      "payable": false,
      "stateMutability": "view",
      "type": "function"
    },
    {
      "constant": false,
      "inputs": [{ "name": "_to", "type": "address" }, { "name": "_value", "type": "uint256" }],
      "name": "transfer",
      "outputs": [{ "name": "", "type": "bool" }],
      "payable": false,
      "stateMutability": "nonpayable",
      "type": "function"
    },
    {
      "constant": true,
      "inputs": [{ "name": "_owner", "type": "address" }, { "name": "_spender", "type": "address" }],
      "name": "allowance",
      "outputs": [{ "name": "", "type": "uint256" }],
      "payable": false,
      "stateMutability": "view",
      "type": "function"
    },
    {
      "anonymous": false,
      "inputs": [
        { "indexed": true, "name": "owner", "type": "address" },
        { "indexed": true, "name": "spender", "type": "address" },
        { "indexed": false, "name": "value", "type": "uint256" }
      ],
      "name": "Approval",
      "type": "event"
    },
    {
      "anonymous": false,
      "inputs": [
        { "indexed": true, "name": "from", "type": "address" },
        { "indexed": true, "name": "to", "type": "address" },
        { "indexed": false, "name": "value", "type": "uint256" }
      ],
      "name": "Transfer",
      "type": "event"
    }
  ];
  
  return abis;
}

/**
 * Updates the abi.ts file with fresh deployments and ABIs
 */
export function updateAbiFile(deployments: Deployments, abis: ABIKP): void {
  try {
    const abiPath = join(process.cwd(), 'abis', 'abi.ts');
    
    let fileContent = `// This file is auto-generated by syncFoundry.ts. Do not edit directly.
import { getAbiItem, Abi } from 'viem'
type Deployments = { [key: string]: { [key: string]: string } };
type ABIKP = { [key: string]: Abi };

export const deployments: Deployments = ${JSON.stringify(deployments, null, 2)};

export const ABIs: ABIKP = ${JSON.stringify(abis, null, 2)};
`;

    // Write the updated file
    writeFileSync(abiPath, fileContent);
    console.log('ABI file updated successfully');
  } catch (err) {
    console.error('Error updating ABI file:', err);
  }
}

/**
 * Synchronize Foundry deployments and ABIs at server startup
 */
export function syncFoundry(): void {
  console.log('Syncing Foundry deployments and ABIs...');
  const deployments = readFoundryDeployments();
  const abis = readFoundryABIs();
  updateAbiFile(deployments, abis);
  console.log('Sync completed');
}

// Run synchronization when the module is loaded
syncFoundry();