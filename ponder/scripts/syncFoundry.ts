/**
 * Script to synchronize Foundry contract ABIs and deployment information with Ponder
 * Converts ES module syntax to CommonJS for compatibility
 */

const fs = require('fs');
const path = require('path');

// Paths
const FOUNDRY_OUT_DIR = path.resolve(__dirname, '../../out');
const PONDER_ABIS_DIR = path.resolve(__dirname, '../abis');
const PONDER_CONFIG_PATH = path.resolve(__dirname, '../ponder.config.ts');

// Contract names to sync
const CONTRACTS = [
  'WillWe',
  'Execution',
  'Will',
  'Membranes'
];

// Starting block for indexing
const START_BLOCK = 24829539; // Block where contracts were deployed on Optimism Sepolia

// Contract addresses on Optimism Sepolia
const CONTRACT_ADDRESSES = {
  'WillWe': '0x70497a8886586f7d63812fb58fc1d1d23da036f8',
  'Execution': '0xf800debf2f9d40a31559d8b072b8ebcb521e7417'
};



/**
 * Main function to sync Foundry contracts with Ponder
 */
async function syncFoundryToPonder() {
  console.log('Starting Foundry to Ponder synchronization...');
  
  try {
    // Sync ABIs
    await syncAbis();

    // Upgrade Deployment addresses
    
    console.log('✅ Foundry to Ponder synchronization complete');
  } catch (error) {
    console.error('❌ Error during synchronization:', error);
    process.exit(1);
  }
}

/**
 * Synchronize ABIs from Foundry to Ponder
 */
async function syncAbis() {
  console.log('Syncing ABIs from Foundry to Ponder...');
  
  // Ensure abis directory exists
  if (!fs.existsSync(PONDER_ABIS_DIR)) {
    fs.mkdirSync(PONDER_ABIS_DIR, { recursive: true });
  }
  
  // Copy each contract ABI
  for (const contractName of CONTRACTS) {
    const sourcePath = path.join(FOUNDRY_OUT_DIR, `${contractName}.sol/${contractName}.json`);
    const targetPath = path.join(PONDER_ABIS_DIR, `${contractName}.json`);
    
    if (fs.existsSync(sourcePath)) {
      console.log(`Found ABI source for ${contractName} at ${sourcePath}`);
      
      // Read the Foundry artifact
      const artifact = JSON.parse(fs.readFileSync(sourcePath, 'utf8'));
      
      // Extract the ABI
      const abi = artifact.abi;
      
      // Write to Ponder abis directory
      fs.writeFileSync(targetPath, JSON.stringify(abi, null, 2));
      console.log(`✅ ABI for ${contractName} copied to ${targetPath}`);
    } else {
      console.warn(`⚠️ Could not find ABI source for ${contractName} at ${sourcePath}`);
    }
  }
}

/**
 * Update Ponder configuration with deployment information
 */

// Run the sync process
syncFoundryToPonder();
