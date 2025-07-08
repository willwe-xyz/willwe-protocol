# WillWe: A Permissionless Proactive Public Organization Structure

## Abstract

The protocol proposes and supports a new way of organizing that centers on distributing fungible units of arbitrary value as signals for communal configuration. This approach is designed to:  

- Cultivate plurality  
- Enhance the legibility of the commons  
- Empower individuals to credibly and continuously commit to political and economic outcomes at all levels  

The resulting structure is envisioned as a novel economic engine enhancing the global prevalence of co-interested value.

---

## Getting Started

### Prerequisites

- [Foundry](https://book.getfoundry.sh/getting-started/installation)
- [Node.js](https://nodejs.org/) (for Ponder indexer)
- [Git](https://git-scm.com/)

### Installation

1. Clone the repository:
   ```bash
   git clone https://github.com/yourusername/willwe.git
   cd willwe
   ```

2. Install dependencies:
   ```bash
   forge install
   cd ponder && npm install
   ```

3. Set up environment variables:
   ```bash
   cp .env.example .env
   cp ponder/.env.example ponder/.env.local
   ```
   
   Edit the `.env` files with your API keys and configuration.

### Building

```bash
forge build
```

### Testing

```bash
forge test
```

### Deployment

Deploy to testnet:
```bash
forge script script/WillWeDeploy2.s.sol --rpc-url $BASE_SEPOLIA_RPC_URL --broadcast
```

---

## Architecture

### Core Contracts

- **WillWe.sol**: Main governance and token contract
- **Execution.sol**: Execution layer for proposals
- **Membranes.sol**: Boundary and access control system
- **Will.sol**: Fungible token implementation

### Indexer

The project uses [Ponder](https://ponder.sh) for blockchain indexing:
- Configuration: `ponder/ponder.config.ts`
- Schema: `ponder/ponder.schema.ts`
- Event handlers: `ponder/src/`

---

## Under Development  

**Protocolized Anarchy**  
_For the on-chain economy_

### How to Contribute  

**Will** is minted and burned for ETH, with linear price growth functioning as:  

- A share of revenue  
- An inter-member arbitrage mechanism  
- A governance token  

Will is continuously utilized within the WillWe protocol to fund its development.  

#### Notes for Early Participants:  

- Participation is encouraged but may initially incur loss.  
- Meaningful engagement is challenging without visual sensemaking tools.  
- While this may hold significant potential, it could also be a foolish endeavor.  
- No assistance is available at this stage to avoid creating long-lasting asymmetries.  

---

## Do-ocracy  

This project operates as a **do-ocracy**—those who take the initiative decide how to act.  

- **Values**: Bias for action, consultation, decentralization  
- **Membership**: Anyone who actively contributes can self-identify as a participant.  
- **Autonomy**: No fixed structures; participants can organize as needed.  
- **Responsibility**: Participants are accountable for their initiatives, optionally collaborating with others.  
- **Lobbying**: Serious concerns about initiatives should be raised directly with responsible parties.  

_Adapted from the [Do-ocracy template](https://communityrule.info/templates/do-ocracy.html)_  

---

## Dasein  

> "Animality falls from its universal, from life, directly into the singleness of Dasein or being-there. The moments of simple determinateness and single organic life, united in this actuality, produce Becoming only as a contingent movement."  

### Key Concepts  

- **Action as the Good**: The cultivation of gifts, capacities, and strengths becomes an end in itself.  
- **Common Education**: Daily interaction fosters a shared education and a vital democracy.  
- **Arbitrary Multiscale Competency**: Encouraging competency across multiple scales.  
- **Goal-Directedness**: Focused on meaningful, collective outcomes.  

---

## Security

⚠️ **Warning**: This project is experimental and under active development. Use at your own risk.

- Smart contracts are not audited
- Test thoroughly before mainnet deployment
- Keep private keys secure
- Regenerate API keys before going public

---

## License

This project is open source. See individual files for specific licensing information.

---

## Deployment Addresses

### Base Mainnet
- WillWe: TBD
- Execution: TBD
- Membranes: TBD
- Will: TBD

### Base Sepolia (Testnet)
- WillWe: TBD
- Execution: TBD
- Membranes: TBD
- Will: TBD