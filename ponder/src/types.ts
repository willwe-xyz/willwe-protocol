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
  
  export interface UserSignal {
    MembraneInflation: [string, string][];
    lastRedistSignal: string[];           
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
  
  export interface NodeState {
    basicInfo: bigint[];
    membraneMeta: string;
    membersOfNode: string[];
    childrenNodes: bigint[];
    movementEndpoints: string[];
    rootPath: bigint[];
    signals: bigint[];
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
    signals: UserSignal[];
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
  
  // Movement and governance types
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
      Action: Movement;  // This should match the Movement interface
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
    return (
      Array.isArray(data?.basicInfo) &&
      data.basicInfo.length === 12 &&
      typeof data.membraneMeta === 'string' &&
      Array.isArray(data.membersOfNode) &&
      Array.isArray(data.childrenNodes) &&
      Array.isArray(data.rootPath) &&
      Array.isArray(data.signals)
    );
  };
  
  export const isValidUserSignal = (data: any): data is UserSignal => {
    return (
      Array.isArray(data?.MembraneInflation) &&
      Array.isArray(data?.lastRedistSignal) &&
      data.MembraneInflation.every((item: any) =>
        Array.isArray(item) &&
        item.length === 2 &&
        typeof item[0] === 'string' &&
        typeof item[1] === 'string'
      )
    );
  };
  
  export const transformNodeData = (nodeData: NodeState): NodeBasicInfo => {
    return {
      nodeId: nodeData.basicInfo[0],
      inflation: nodeData.basicInfo[1],
      balanceAnchor: nodeData.basicInfo[2],
      balanceBudget: nodeData.basicInfo[3],
      rootValuationBudget: nodeData.basicInfo[4],
      rootValuationReserve: nodeData.basicInfo[5],
      membraneId: nodeData.basicInfo[6],
      eligibilityPerSec: nodeData.basicInfo[7],
      lastRedistribution: nodeData.basicInfo[8],
      balanceOfUser: nodeData.basicInfo[9],
      endpointOfUserForNode: nodeData.basicInfo[10],
      totalSupply: nodeData.basicInfo[11]
    };
  };