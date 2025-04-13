export interface NodeBasicInfo {
    nodeId: string;                    
    inflation: string;                 
    balanceAnchor: string;            
    balanceBudget: string;            
    rootValuationBudget: string;      
    rootValuationReserve: string;     
    membraneId: string;               
    eligibilityPerSec: string;        
    lastRedistribution: string;       
    balanceOfUser: string;            
    endpointOfUserForNode: string;    
    totalSupply: string;              
  }
  
  
  export interface MembraneMetadata {
    name: string;
    id: string;
    description?: string;
    characteristics: MembraneCharacteristic[];
    membershipConditions: {
      tokenAddress: string;
      requiredBalance: string;
    }[];
    createdAt: string;
  }
  
  export interface AllNodeSignals {
    signalers: string[];
    inflationSignals: [string, string][]; // [address, value] pairs
    membraneSignals: [string, string][]; // [address, value] pairs
    redistributionSignals: string[][]; // Array of arrays of strings
  }
  
  export interface NodeState {
    basicInfo: any; // The contract returns either an array or an object
    membraneMeta: string;
    membersOfNode: string[];
    childrenNodes: string[];
    movementEndpoints: string[];
    rootPath: string[];
    nodeSignals?: AllNodeSignals; // Optional because older versions might still use 'signals'
    signals?: string[]; // Kept for backwards compatibility
  }
  
  export interface MovementInfo {
    category: number;
    initiator: string;
    exeAccount: string;
    viaNode: bigint;
    expiresAt: bigint;
    description: string;
    executedPayload: string;
  }
  
  export interface SignatureQueueInfo {
    state: number;
    signers: string[];
    signatures: string[];
  }
  
  export interface MembraneInfo {
    membraneId: bigint;
    tokens: string[];
    balances: bigint[];
    metadataCID: string;
  }
  
  export interface MembraneRequirement {
    tokenAddress: string;
    symbol: string;
    requiredBalance: string;
    formattedBalance: string;
  }
  
  export interface MembraneCharacteristic {
    title: string;
    link?: string;
  }
  
  export interface TransformedNodeData {
    basicInfo: NodeBasicInfo;
    membraneMeta: string;
    membersOfNode: string[];
    childrenNodes: string[];
    rootPath: string[];
    signals: string[]; 
    ancestors: string[];
  }
  
  export interface NodeStats {
    totalValue: string;
    dailyGrowth: string;
    memberCount: number;
    childCount: number;
    pathDepth: number;
  }
  
  export interface MembraneState {
    tokens: string[];
    balances: string[];
    meta: string;
    createdAt: string;
  }
  
  export interface NodeQueryResponse {
    data: NodeState;
    isLoading: boolean;
    error: Error | null;
    refetch: () => Promise<void>;
  }
  
  export interface NodeOperationParams {
    nodeId: string;
    chainId: string;
    options?: {
      gasLimit?: number;
      gasPrice?: string;
    };
  }
  
  export interface SignalData {
    membrane: string;
    inflation: string;
    timestamp: number;
    value: string;
  }
  
  export enum MovementType {
    Revert = 0,
    AgentMajority = 1,
    EnergeticMajority = 2
  }
  
  export enum SignatureQueueState {
    None = 0,
    Initialized = 1,
    Valid = 2,
    Executed = 3,
    Stale = 4
  }
  
  export interface Call {
    target: string;
    callData: string;
    value: string;
  }
  
  export interface Movement {
    category: MovementType;
    initiatior: string;
    exeAccount: string;
    viaNode: string;
    expiresAt: string;
    description: string;
    executedPayload: string;
  }
  
  export interface SignatureQueue {
    state: SignatureQueueState;
    Action: Movement;
    Signers: string[];
    Sigs: string[];
  }
  
  export interface LatentMovement {
    movement: Movement;
    signatureQueue: {
      state: SignatureQueueState;
      Action: Movement;  
      Signers: string[];
      Sigs: string[];
    };
    movementHash: string;
  }
  
  export interface IPFSMetadata {
    description: string;
    timestamp: number;
  }
  
  export interface MovementDescription {
    description: string;
    timestamp: number;
  }
  
  export interface MovementSignatureStatus {
    current: number;
    required: number;
    hasUserSigned: boolean;
  }
  
  ///////////////////////////////////////////
  // Type guard functions
  ///////////////////////////////////////////
  export const isValidNodeState = (data: any): data is NodeState => {
    if (!data) return false;
    
    // Check if membraneMeta exists and is a string
    if (typeof data.membraneMeta !== 'string') return false;
    
    // Check that all required array properties exist
    if (!Array.isArray(data.membersOfNode) ||
        !Array.isArray(data.childrenNodes) ||
        !Array.isArray(data.rootPath)) {
      return false;
    }
    
    // Check for either signals or nodeSignals (at least one should exist)
    if (!Array.isArray(data.signals) && !data.nodeSignals) {
      return false;
    }
    
    // If nodeSignals exists, validate its structure
    if (data.nodeSignals) {
      if (!Array.isArray(data.nodeSignals.signalers)) return false;
      // Don't require the signal arrays as they might be empty
    }
    
    // Check if basicInfo exists (can be either array or object)
    if (!data.basicInfo) return false;
    
    // If basicInfo is an array, check that it has 12 elements
    if (Array.isArray(data.basicInfo) && data.basicInfo.length !== 12) {
      return false;
    }
    
    // If basicInfo is an object, check for required fields
    if (!Array.isArray(data.basicInfo) && typeof data.basicInfo === 'object') {
      const requiredKeys = ['nodeId', 'inflation', 'membraneId', 'totalSupply'];
      for (const key of requiredKeys) {
        if (data.basicInfo[key] === undefined) return false;
      }
    }
    
    return true;
  };
  
  
  export const transformNodeData = (nodeData: NodeState): NodeBasicInfo => {
    // Handle the case where basicInfo is already an object
    if (!Array.isArray(nodeData.basicInfo) && typeof nodeData.basicInfo === 'object') {
      const basicInfo = nodeData.basicInfo;
      return {
        nodeId: basicInfo.nodeId?.toString() || "0",
        inflation: basicInfo.inflation?.toString() || "0",
        balanceAnchor: basicInfo.balanceAnchor?.toString() || "0",
        balanceBudget: basicInfo.balanceBudget?.toString() || "0",
        rootValuationBudget: basicInfo.rootValuationBudget?.toString() || "0",
        rootValuationReserve: basicInfo.rootValuationReserve?.toString() || "0",
        membraneId: basicInfo.membraneId?.toString() || "0",
        eligibilityPerSec: basicInfo.eligibilityPerSec?.toString() || "0",
        lastRedistribution: basicInfo.lastRedistribution?.toString() || "0",
        balanceOfUser: basicInfo.balanceOfUser?.toString() || "0",
        endpointOfUserForNode: basicInfo.endpointOfUserForNode?.toString() || "0x0000000000000000000000000000000000000000",
        totalSupply: basicInfo.totalSupply?.toString() || "0"
      };
    }
    
    // Handle the case where basicInfo is an array
    if (Array.isArray(nodeData.basicInfo)) {
      // Safely handle array indexes
      const safeGet = (index: number, defaultValue: string = "0") => {
        return (nodeData.basicInfo[index] !== undefined) ? 
          nodeData.basicInfo[index]?.toString() : defaultValue;
      };
      
      return {
        nodeId: safeGet(0),
        inflation: safeGet(1),
        balanceAnchor: safeGet(2),
        balanceBudget: safeGet(3),
        rootValuationBudget: safeGet(4),
        rootValuationReserve: safeGet(5),
        membraneId: safeGet(6),
        eligibilityPerSec: safeGet(7),
        lastRedistribution: safeGet(8),
        balanceOfUser: safeGet(9),
        endpointOfUserForNode: safeGet(10, "0x0000000000000000000000000000000000000000"),
        totalSupply: safeGet(11)
      };
    }
    
    // Default empty response
    return {
      nodeId: "0",
      inflation: "0",
      balanceAnchor: "0",
      balanceBudget: "0",
      rootValuationBudget: "0",
      rootValuationReserve: "0",
      membraneId: "0",
      eligibilityPerSec: "0",
      lastRedistribution: "0",
      balanceOfUser: "0",
      endpointOfUserForNode: "0x0000000000000000000000000000000000000000",
      totalSupply: "0"
    };
  };