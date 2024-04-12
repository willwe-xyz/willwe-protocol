export const FUNADDRESS = {
   59140 : "0x730d8B0e5eCa3180C2F55d3Bb82247806E716F65",
   84531: "0xDFf2a89B8DB2BA17bc4b9b2A81935d5154a6a4f3"
}
export const FunABI =  [
  {
    "inputs": [
      {
        "internalType": "address",
        "name": "ExeAddr",
        "type": "address"
      }
    ],
    "stateMutability": "nonpayable",
    "type": "constructor"
  },
  {
    "inputs": [],
    "name": "AlreadyMember",
    "type": "error"
  },
  {
    "inputs": [],
    "name": "BadLen",
    "type": "error"
  },
  {
    "inputs": [],
    "name": "BaseOrNonFungible",
    "type": "error"
  },
  {
    "inputs": [],
    "name": "BranchAlreadyExists",
    "type": "error"
  },
  {
    "inputs": [],
    "name": "BranchNotFound",
    "type": "error"
  },
  {
    "inputs": [],
    "name": "BurnE20TransferFailed",
    "type": "error"
  },
  {
    "inputs": [],
    "name": "CoreGasTransferFailed",
    "type": "error"
  },
  {
    "inputs": [],
    "name": "EOA",
    "type": "error"
  },
  {
    "inputs": [],
    "name": "ERCGasHog",
    "type": "error"
  },
  {
    "inputs": [],
    "name": "ExecutionOnly",
    "type": "error"
  },
  {
    "inputs": [],
    "name": "GasHogOrLightFx",
    "type": "error"
  },
  {
    "inputs": [],
    "name": "InsufficientRootBalance",
    "type": "error"
  },
  {
    "inputs": [],
    "name": "Internal",
    "type": "error"
  },
  {
    "inputs": [],
    "name": "MembershipOp",
    "type": "error"
  },
  {
    "inputs": [],
    "name": "Membrane__EmptyFieldOnMembraneCreation",
    "type": "error"
  },
  {
    "inputs": [],
    "name": "MintE20TransferFailed",
    "type": "error"
  },
  {
    "inputs": [],
    "name": "No",
    "type": "error"
  },
  {
    "inputs": [],
    "name": "NoMembership",
    "type": "error"
  },
  {
    "inputs": [],
    "name": "NoSoup",
    "type": "error"
  },
  {
    "inputs": [],
    "name": "Noise",
    "type": "error"
  },
  {
    "inputs": [],
    "name": "NotMember",
    "type": "error"
  },
  {
    "inputs": [],
    "name": "RootExists",
    "type": "error"
  },
  {
    "inputs": [],
    "name": "UnallowedAmount",
    "type": "error"
  },
  {
    "inputs": [],
    "name": "UninstantiatedMembrane",
    "type": "error"
  },
  {
    "inputs": [],
    "name": "Unqualified",
    "type": "error"
  },
  {
    "inputs": [],
    "name": "UnregisteredFungible",
    "type": "error"
  },
  {
    "inputs": [],
    "name": "UnsupportedTransfer",
    "type": "error"
  },
  {
    "inputs": [],
    "name": "membraneNotFound",
    "type": "error"
  },
  {
    "anonymous": false,
    "inputs": [
      {
        "indexed": true,
        "internalType": "address",
        "name": "account",
        "type": "address"
      },
      {
        "indexed": true,
        "internalType": "address",
        "name": "operator",
        "type": "address"
      },
      {
        "indexed": false,
        "internalType": "bool",
        "name": "approved",
        "type": "bool"
      }
    ],
    "name": "ApprovalForAll",
    "type": "event"
  },
  {
    "anonymous": false,
    "inputs": [
      {
        "indexed": false,
        "internalType": "uint256",
        "name": "Fungible",
        "type": "uint256"
      },
      {
        "indexed": false,
        "internalType": "uint256",
        "name": "Amount",
        "type": "uint256"
      },
      {
        "indexed": false,
        "internalType": "address",
        "name": "Who",
        "type": "address"
      }
    ],
    "name": "Burned",
    "type": "event"
  },
  {
    "anonymous": false,
    "inputs": [
      {
        "indexed": false,
        "internalType": "address",
        "name": "they",
        "type": "address"
      },
      {
        "indexed": false,
        "internalType": "uint256",
        "name": "membrane",
        "type": "uint256"
      }
    ],
    "name": "ChangedMembrane",
    "type": "event"
  },
  {
    "anonymous": false,
    "inputs": [
      {
        "indexed": false,
        "internalType": "uint256",
        "name": "id",
        "type": "uint256"
      },
      {
        "indexed": false,
        "internalType": "string",
        "name": "metadata",
        "type": "string"
      }
    ],
    "name": "CreatedMembrane",
    "type": "event"
  },
  {
    "anonymous": false,
    "inputs": [
      {
        "indexed": false,
        "internalType": "address",
        "name": "who",
        "type": "address"
      },
      {
        "indexed": false,
        "internalType": "bytes4",
        "name": "fxSig",
        "type": "bytes4"
      },
      {
        "indexed": false,
        "internalType": "uint256",
        "name": "gasCost",
        "type": "uint256"
      }
    ],
    "name": "GasUsedWithCost",
    "type": "event"
  },
  {
    "anonymous": false,
    "inputs": [
      {
        "indexed": true,
        "internalType": "uint256",
        "name": "targetNode",
        "type": "uint256"
      },
      {
        "indexed": false,
        "internalType": "uint256",
        "name": "newInflation",
        "type": "uint256"
      }
    ],
    "name": "InflationChanged",
    "type": "event"
  },
  {
    "anonymous": false,
    "inputs": [
      {
        "indexed": true,
        "internalType": "uint256",
        "name": "targetNode",
        "type": "uint256"
      },
      {
        "indexed": false,
        "internalType": "uint256",
        "name": "membraneID",
        "type": "uint256"
      }
    ],
    "name": "MembraneChanged",
    "type": "event"
  },
  {
    "anonymous": false,
    "inputs": [
      {
        "indexed": false,
        "internalType": "uint256",
        "name": "node",
        "type": "uint256"
      },
      {
        "indexed": false,
        "internalType": "uint256",
        "name": "amount",
        "type": "uint256"
      }
    ],
    "name": "MintedInflation",
    "type": "event"
  },
  {
    "anonymous": false,
    "inputs": [
      {
        "indexed": true,
        "internalType": "uint256",
        "name": "Parent",
        "type": "uint256"
      },
      {
        "indexed": true,
        "internalType": "uint256",
        "name": "newBranch",
        "type": "uint256"
      }
    ],
    "name": "NewEntityCreated",
    "type": "event"
  },
  {
    "anonymous": false,
    "inputs": [
      {
        "indexed": true,
        "internalType": "address",
        "name": "ERC20Root",
        "type": "address"
      }
    ],
    "name": "NewRootRegistered",
    "type": "event"
  },
  {
    "anonymous": false,
    "inputs": [
      {
        "indexed": false,
        "internalType": "address",
        "name": "who",
        "type": "address"
      },
      {
        "indexed": true,
        "internalType": "uint256",
        "name": "fromWhere",
        "type": "uint256"
      }
    ],
    "name": "RenouncedMembership",
    "type": "event"
  },
  {
    "anonymous": false,
    "inputs": [
      {
        "indexed": true,
        "internalType": "uint256",
        "name": "newEntity",
        "type": "uint256"
      },
      {
        "indexed": false,
        "internalType": "uint256",
        "name": "usedMembrane",
        "type": "uint256"
      }
    ],
    "name": "SpawnedWithMembrane",
    "type": "event"
  },
  {
    "anonymous": false,
    "inputs": [
      {
        "indexed": true,
        "internalType": "address",
        "name": "operator",
        "type": "address"
      },
      {
        "indexed": true,
        "internalType": "address",
        "name": "from",
        "type": "address"
      },
      {
        "indexed": true,
        "internalType": "address",
        "name": "to",
        "type": "address"
      },
      {
        "indexed": false,
        "internalType": "uint256[]",
        "name": "ids",
        "type": "uint256[]"
      },
      {
        "indexed": false,
        "internalType": "uint256[]",
        "name": "values",
        "type": "uint256[]"
      }
    ],
    "name": "TransferBatch",
    "type": "event"
  },
  {
    "anonymous": false,
    "inputs": [
      {
        "indexed": true,
        "internalType": "address",
        "name": "operator",
        "type": "address"
      },
      {
        "indexed": true,
        "internalType": "address",
        "name": "from",
        "type": "address"
      },
      {
        "indexed": true,
        "internalType": "address",
        "name": "to",
        "type": "address"
      },
      {
        "indexed": false,
        "internalType": "uint256",
        "name": "id",
        "type": "uint256"
      },
      {
        "indexed": false,
        "internalType": "uint256",
        "name": "value",
        "type": "uint256"
      }
    ],
    "name": "TransferSingle",
    "type": "event"
  },
  {
    "anonymous": false,
    "inputs": [
      {
        "indexed": false,
        "internalType": "string",
        "name": "value",
        "type": "string"
      },
      {
        "indexed": true,
        "internalType": "uint256",
        "name": "id",
        "type": "uint256"
      }
    ],
    "name": "URI",
    "type": "event"
  },
  {
    "anonymous": false,
    "inputs": [
      {
        "indexed": true,
        "internalType": "address",
        "name": "who",
        "type": "address"
      }
    ],
    "name": "gCheckKick",
    "type": "event"
  },
  {
    "inputs": [],
    "name": "RVT",
    "outputs": [
      {
        "internalType": "address",
        "name": "",
        "type": "address"
      }
    ],
    "stateMutability": "view",
    "type": "function"
  },
  {
    "inputs": [
      {
        "internalType": "uint256",
        "name": "fid_",
        "type": "uint256"
      }
    ],
    "name": "allMembersOf",
    "outputs": [
      {
        "internalType": "address[]",
        "name": "",
        "type": "address[]"
      }
    ],
    "stateMutability": "view",
    "type": "function"
  },
  {
    "inputs": [
      {
        "internalType": "address",
        "name": "account",
        "type": "address"
      },
      {
        "internalType": "uint256",
        "name": "id",
        "type": "uint256"
      }
    ],
    "name": "balanceOf",
    "outputs": [
      {
        "internalType": "uint256",
        "name": "",
        "type": "uint256"
      }
    ],
    "stateMutability": "view",
    "type": "function"
  },
  {
    "inputs": [
      {
        "internalType": "address[]",
        "name": "accounts",
        "type": "address[]"
      },
      {
        "internalType": "uint256[]",
        "name": "ids",
        "type": "uint256[]"
      }
    ],
    "name": "balanceOfBatch",
    "outputs": [
      {
        "internalType": "uint256[]",
        "name": "",
        "type": "uint256[]"
      }
    ],
    "stateMutability": "view",
    "type": "function"
  },
  {
    "inputs": [
      {
        "internalType": "uint256",
        "name": "fid_",
        "type": "uint256"
      },
      {
        "internalType": "uint256",
        "name": "amount_",
        "type": "uint256"
      }
    ],
    "name": "burn",
    "outputs": [
      {
        "internalType": "bool",
        "name": "",
        "type": "bool"
      }
    ],
    "stateMutability": "nonpayable",
    "type": "function"
  },
  {
    "inputs": [
      {
        "internalType": "uint256",
        "name": "nodeId_",
        "type": "uint256"
      },
      {
        "internalType": "address",
        "name": "owner",
        "type": "address"
      }
    ],
    "name": "createEndpointForOwner",
    "outputs": [
      {
        "internalType": "address",
        "name": "endpoint",
        "type": "address"
      }
    ],
    "stateMutability": "nonpayable",
    "type": "function"
  },
  {
    "inputs": [
      {
        "internalType": "address[]",
        "name": "tokens_",
        "type": "address[]"
      },
      {
        "internalType": "uint256[]",
        "name": "balances_",
        "type": "uint256[]"
      },
      {
        "internalType": "string",
        "name": "meta_",
        "type": "string"
      }
    ],
    "name": "createMembrane",
    "outputs": [
      {
        "internalType": "uint256",
        "name": "id",
        "type": "uint256"
      }
    ],
    "stateMutability": "nonpayable",
    "type": "function"
  },
  {
    "inputs": [
      {
        "internalType": "address",
        "name": "endpointAddress",
        "type": "address"
      }
    ],
    "name": "endpointOwner",
    "outputs": [
      {
        "internalType": "uint256",
        "name": "",
        "type": "uint256"
      }
    ],
    "stateMutability": "view",
    "type": "function"
  },
  {
    "inputs": [
      {
        "internalType": "bytes32",
        "name": "SignatureQueueHash_",
        "type": "bytes32"
      }
    ],
    "name": "executeQueue",
    "outputs": [
      {
        "internalType": "bool",
        "name": "s",
        "type": "bool"
      }
    ],
    "stateMutability": "nonpayable",
    "type": "function"
  },
  {
    "inputs": [],
    "name": "executionAddress",
    "outputs": [
      {
        "internalType": "address",
        "name": "",
        "type": "address"
      }
    ],
    "stateMutability": "view",
    "type": "function"
  },
  {
    "inputs": [
      {
        "internalType": "address",
        "name": "who_",
        "type": "address"
      },
      {
        "internalType": "uint256",
        "name": "membraneID_",
        "type": "uint256"
      }
    ],
    "name": "gCheck",
    "outputs": [
      {
        "internalType": "bool",
        "name": "s",
        "type": "bool"
      }
    ],
    "stateMutability": "view",
    "type": "function"
  },
  {
    "inputs": [
      {
        "internalType": "uint256",
        "name": "fid_",
        "type": "uint256"
      }
    ],
    "name": "getChildrenOf",
    "outputs": [
      {
        "internalType": "uint256[]",
        "name": "",
        "type": "uint256[]"
      }
    ],
    "stateMutability": "view",
    "type": "function"
  },
  {
    "inputs": [
      {
        "internalType": "uint256",
        "name": "fid_",
        "type": "uint256"
      }
    ],
    "name": "getInUseMembraneOf",
    "outputs": [
      {
        "components": [
          {
            "internalType": "address[]",
            "name": "tokens",
            "type": "address[]"
          },
          {
            "internalType": "uint256[]",
            "name": "balances",
            "type": "uint256[]"
          },
          {
            "internalType": "string",
            "name": "meta",
            "type": "string"
          }
        ],
        "internalType": "struct IMembrane.Membrane",
        "name": "",
        "type": "tuple"
      }
    ],
    "stateMutability": "view",
    "type": "function"
  },
  {
    "inputs": [
      {
        "internalType": "uint256",
        "name": "fid_",
        "type": "uint256"
      }
    ],
    "name": "getMembraneOf",
    "outputs": [
      {
        "internalType": "uint256",
        "name": "",
        "type": "uint256"
      }
    ],
    "stateMutability": "view",
    "type": "function"
  },
  {
    "inputs": [
      {
        "internalType": "uint256",
        "name": "fid_",
        "type": "uint256"
      }
    ],
    "name": "getParentOf",
    "outputs": [
      {
        "internalType": "uint256",
        "name": "",
        "type": "uint256"
      }
    ],
    "stateMutability": "view",
    "type": "function"
  },
  {
    "inputs": [
      {
        "internalType": "bytes32",
        "name": "hash_",
        "type": "bytes32"
      }
    ],
    "name": "getSigQueue",
    "outputs": [
      {
        "components": [
          {
            "internalType": "enum SQState",
            "name": "state",
            "type": "uint8"
          },
          {
            "components": [
              {
                "internalType": "enum MovementType",
                "name": "category",
                "type": "uint8"
              },
              {
                "internalType": "address",
                "name": "initiatior",
                "type": "address"
              },
              {
                "internalType": "address",
                "name": "exeAccount",
                "type": "address"
              },
              {
                "internalType": "uint256",
                "name": "viaNode",
                "type": "uint256"
              },
              {
                "internalType": "uint256",
                "name": "expiresAt",
                "type": "uint256"
              },
              {
                "internalType": "bytes32",
                "name": "descriptionHash",
                "type": "bytes32"
              },
              {
                "internalType": "bytes",
                "name": "data",
                "type": "bytes"
              }
            ],
            "internalType": "struct Movement",
            "name": "Action",
            "type": "tuple"
          },
          {
            "internalType": "address[]",
            "name": "Signers",
            "type": "address[]"
          },
          {
            "internalType": "bytes[]",
            "name": "Sigs",
            "type": "bytes[]"
          }
        ],
        "internalType": "struct SignatureQueue",
        "name": "",
        "type": "tuple"
      }
    ],
    "stateMutability": "view",
    "type": "function"
  },
  {
    "inputs": [
      {
        "internalType": "address",
        "name": "user_",
        "type": "address"
      }
    ],
    "name": "getUserInteractions",
    "outputs": [
      {
        "internalType": "uint256[][2]",
        "name": "activeBalances",
        "type": "uint256[][2]"
      }
    ],
    "stateMutability": "view",
    "type": "function"
  },
  {
    "inputs": [
      {
        "internalType": "uint256",
        "name": "nodeId",
        "type": "uint256"
      }
    ],
    "name": "inflationOf",
    "outputs": [
      {
        "internalType": "uint256",
        "name": "",
        "type": "uint256"
      }
    ],
    "stateMutability": "view",
    "type": "function"
  },
  {
    "inputs": [
      {
        "internalType": "address",
        "name": "account",
        "type": "address"
      },
      {
        "internalType": "address",
        "name": "operator",
        "type": "address"
      }
    ],
    "name": "isApprovedForAll",
    "outputs": [
      {
        "internalType": "bool",
        "name": "",
        "type": "bool"
      }
    ],
    "stateMutability": "view",
    "type": "function"
  },
  {
    "inputs": [
      {
        "internalType": "address",
        "name": "whoabout_",
        "type": "address"
      },
      {
        "internalType": "uint256",
        "name": "whereabout_",
        "type": "uint256"
      }
    ],
    "name": "isMember",
    "outputs": [
      {
        "internalType": "bool",
        "name": "",
        "type": "bool"
      }
    ],
    "stateMutability": "view",
    "type": "function"
  },
  {
    "inputs": [
      {
        "internalType": "bytes32",
        "name": "_hash",
        "type": "bytes32"
      },
      {
        "internalType": "bytes",
        "name": "_signature",
        "type": "bytes"
      }
    ],
    "name": "isValidSignature",
    "outputs": [
      {
        "internalType": "bytes4",
        "name": "",
        "type": "bytes4"
      }
    ],
    "stateMutability": "view",
    "type": "function"
  },
  {
    "inputs": [
      {
        "internalType": "address",
        "name": "endpoint_",
        "type": "address"
      },
      {
        "internalType": "uint256",
        "name": "endpointParent_",
        "type": "uint256"
      },
      {
        "internalType": "address",
        "name": "endpointOwner_",
        "type": "address"
      }
    ],
    "name": "localizeEndpoint",
    "outputs": [],
    "stateMutability": "nonpayable",
    "type": "function"
  },
  {
    "inputs": [
      {
        "internalType": "address",
        "name": "target",
        "type": "address"
      },
      {
        "internalType": "uint256",
        "name": "fid_",
        "type": "uint256"
      }
    ],
    "name": "membershipEnforce",
    "outputs": [
      {
        "internalType": "bool",
        "name": "s",
        "type": "bool"
      }
    ],
    "stateMutability": "nonpayable",
    "type": "function"
  },
  {
    "inputs": [
      {
        "internalType": "uint256",
        "name": "fid_",
        "type": "uint256"
      }
    ],
    "name": "membershipID",
    "outputs": [
      {
        "internalType": "uint256",
        "name": "",
        "type": "uint256"
      }
    ],
    "stateMutability": "pure",
    "type": "function"
  },
  {
    "inputs": [
      {
        "internalType": "uint256",
        "name": "fid_",
        "type": "uint256"
      },
      {
        "internalType": "uint256",
        "name": "amount_",
        "type": "uint256"
      }
    ],
    "name": "mint",
    "outputs": [],
    "stateMutability": "nonpayable",
    "type": "function"
  },
  {
    "inputs": [
      {
        "internalType": "uint256",
        "name": "node",
        "type": "uint256"
      }
    ],
    "name": "mintInflation",
    "outputs": [
      {
        "internalType": "uint256",
        "name": "amount",
        "type": "uint256"
      }
    ],
    "stateMutability": "nonpayable",
    "type": "function"
  },
  {
    "inputs": [
      {
        "internalType": "uint256",
        "name": "fid_",
        "type": "uint256"
      },
      {
        "internalType": "address",
        "name": "to_",
        "type": "address"
      }
    ],
    "name": "mintMembership",
    "outputs": [
      {
        "internalType": "uint256",
        "name": "mID",
        "type": "uint256"
      }
    ],
    "stateMutability": "nonpayable",
    "type": "function"
  },
  {
    "inputs": [
      {
        "internalType": "uint256",
        "name": "typeOfMovement",
        "type": "uint256"
      },
      {
        "internalType": "uint256",
        "name": "node_",
        "type": "uint256"
      },
      {
        "internalType": "uint256",
        "name": "expiresInDays",
        "type": "uint256"
      },
      {
        "internalType": "address",
        "name": "executingAccount",
        "type": "address"
      },
      {
        "internalType": "bytes32",
        "name": "descriptionHash",
        "type": "bytes32"
      },
      {
        "internalType": "bytes",
        "name": "data",
        "type": "bytes"
      }
    ],
    "name": "proposeMovement",
    "outputs": [
      {
        "internalType": "bytes32",
        "name": "movementHash",
        "type": "bytes32"
      }
    ],
    "stateMutability": "nonpayable",
    "type": "function"
  },
  {
    "inputs": [
      {
        "internalType": "uint256",
        "name": "nodeId_",
        "type": "uint256"
      }
    ],
    "name": "redistribute",
    "outputs": [
      {
        "internalType": "uint256",
        "name": "distributedAmt",
        "type": "uint256"
      }
    ],
    "stateMutability": "nonpayable",
    "type": "function"
  },
  {
    "inputs": [
      {
        "internalType": "address",
        "name": "from",
        "type": "address"
      },
      {
        "internalType": "address",
        "name": "to",
        "type": "address"
      },
      {
        "internalType": "uint256[]",
        "name": "ids",
        "type": "uint256[]"
      },
      {
        "internalType": "uint256[]",
        "name": "amounts",
        "type": "uint256[]"
      },
      {
        "internalType": "bytes",
        "name": "data",
        "type": "bytes"
      }
    ],
    "name": "safeBatchTransferFrom",
    "outputs": [],
    "stateMutability": "nonpayable",
    "type": "function"
  },
  {
    "inputs": [
      {
        "internalType": "address",
        "name": "from",
        "type": "address"
      },
      {
        "internalType": "address",
        "name": "to",
        "type": "address"
      },
      {
        "internalType": "uint256",
        "name": "id",
        "type": "uint256"
      },
      {
        "internalType": "uint256",
        "name": "amount",
        "type": "uint256"
      },
      {
        "internalType": "bytes",
        "name": "data",
        "type": "bytes"
      }
    ],
    "name": "safeTransferFrom",
    "outputs": [],
    "stateMutability": "nonpayable",
    "type": "function"
  },
  {
    "inputs": [
      {
        "internalType": "uint256",
        "name": "targetNode_",
        "type": "uint256"
      },
      {
        "internalType": "uint256[]",
        "name": "signals",
        "type": "uint256[]"
      }
    ],
    "name": "sendSignal",
    "outputs": [
      {
        "internalType": "bool",
        "name": "s",
        "type": "bool"
      }
    ],
    "stateMutability": "nonpayable",
    "type": "function"
  },
  {
    "inputs": [
      {
        "internalType": "address",
        "name": "operator",
        "type": "address"
      },
      {
        "internalType": "bool",
        "name": "approved",
        "type": "bool"
      }
    ],
    "name": "setApprovalForAll",
    "outputs": [],
    "stateMutability": "nonpayable",
    "type": "function"
  },
  {
    "inputs": [
      {
        "internalType": "uint256",
        "name": "fid_",
        "type": "uint256"
      }
    ],
    "name": "spawnBranch",
    "outputs": [
      {
        "internalType": "uint256",
        "name": "newID",
        "type": "uint256"
      }
    ],
    "stateMutability": "nonpayable",
    "type": "function"
  },
  {
    "inputs": [
      {
        "internalType": "uint256",
        "name": "fid_",
        "type": "uint256"
      },
      {
        "internalType": "uint256",
        "name": "membraneID_",
        "type": "uint256"
      }
    ],
    "name": "spawnBranchWithMembrane",
    "outputs": [
      {
        "internalType": "uint256",
        "name": "newID",
        "type": "uint256"
      }
    ],
    "stateMutability": "nonpayable",
    "type": "function"
  },
  {
    "inputs": [
      {
        "internalType": "address",
        "name": "fungible20_",
        "type": "address"
      }
    ],
    "name": "spawnRootBranch",
    "outputs": [
      {
        "internalType": "uint256",
        "name": "fID",
        "type": "uint256"
      }
    ],
    "stateMutability": "nonpayable",
    "type": "function"
  },
  {
    "inputs": [
      {
        "internalType": "bytes32",
        "name": "sigHash",
        "type": "bytes32"
      },
      {
        "internalType": "address[]",
        "name": "signers",
        "type": "address[]"
      },
      {
        "internalType": "bytes[]",
        "name": "signatures",
        "type": "bytes[]"
      }
    ],
    "name": "submitSignatures",
    "outputs": [],
    "stateMutability": "nonpayable",
    "type": "function"
  },
  {
    "inputs": [
      {
        "internalType": "bytes4",
        "name": "interfaceId",
        "type": "bytes4"
      }
    ],
    "name": "supportsInterface",
    "outputs": [
      {
        "internalType": "bool",
        "name": "",
        "type": "bool"
      }
    ],
    "stateMutability": "view",
    "type": "function"
  },
  {
    "inputs": [
      {
        "internalType": "address",
        "name": "rootToken_",
        "type": "address"
      },
      {
        "internalType": "uint256",
        "name": "taxDivBy_",
        "type": "uint256"
      }
    ],
    "name": "taxPolicyPreference",
    "outputs": [
      {
        "internalType": "uint256",
        "name": "inForceTaxRate",
        "type": "uint256"
      }
    ],
    "stateMutability": "nonpayable",
    "type": "function"
  },
  {
    "inputs": [
      {
        "internalType": "uint256",
        "name": "x",
        "type": "uint256"
      }
    ],
    "name": "toAddress",
    "outputs": [
      {
        "internalType": "address",
        "name": "",
        "type": "address"
      }
    ],
    "stateMutability": "view",
    "type": "function"
  },
  {
    "inputs": [
      {
        "internalType": "address",
        "name": "x",
        "type": "address"
      }
    ],
    "name": "toID",
    "outputs": [
      {
        "internalType": "uint256",
        "name": "",
        "type": "uint256"
      }
    ],
    "stateMutability": "view",
    "type": "function"
  },
  {
    "inputs": [
      {
        "internalType": "uint256",
        "name": "nodeId",
        "type": "uint256"
      }
    ],
    "name": "totalSupply",
    "outputs": [
      {
        "internalType": "uint256",
        "name": "",
        "type": "uint256"
      }
    ],
    "stateMutability": "view",
    "type": "function"
  },
  {
    "inputs": [
      {
        "internalType": "uint256",
        "name": "",
        "type": "uint256"
      }
    ],
    "name": "totalSupplyOf",
    "outputs": [
      {
        "internalType": "uint256",
        "name": "",
        "type": "uint256"
      }
    ],
    "stateMutability": "view",
    "type": "function"
  },
  {
    "inputs": [
      {
        "internalType": "uint256",
        "name": "",
        "type": "uint256"
      }
    ],
    "name": "uri",
    "outputs": [
      {
        "internalType": "string",
        "name": "",
        "type": "string"
      }
    ],
    "stateMutability": "view",
    "type": "function"
  }
]