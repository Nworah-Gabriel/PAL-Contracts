# PAL Business Management System

A comprehensive on-chain business management system built on Base blockchain that enables businesses to track finances, manage projects, and automate financial insights.

## 🎯 Overview

PAL is a decentralized business management platform that provides:
- **On-chain business account management**
- **Real-time financial tracking** (sales, expenses, profits)
- **Project and client management**
- **Automated financial alerts**
- **AI-ready data structure** for future insights

Built with **Solidity 0.8.30** and **Foundry** for maximum security and efficiency.

## 🚀 Features

### Core MVP Features
- ✅ **Business Account Setup** - Unique on-chain business identities
- ✅ **Transaction Recording** - Sales, purchases, and expense tracking
- ✅ **Profit & Balance Tracking** - Automated financial calculations
- ✅ **Project Management** - Client projects with deadlines and status
- ✅ **Smart Alerts** - Low balance and overspending notifications
- ✅ **Access Control** - Team admin functions and user permissions

### Future Features
- 🔄 **Reward System** - PAL token incentives for active users
- 🔄 **Advanced Analytics** - AI-powered business insights
- 🔄 **Invoice Management** - Blockchain-based invoicing
- 🔄 **Multi-chain Support** - Cross-chain business management

# 🏗️ System Architecture


## High-Level Overview

```mermaid
graph TB
    subgraph "Frontend Layer"
        A[Web DApp]
        B[Mobile App]
        C[Admin Dashboard]
    end

    subgraph "Application Layer"
        D[PAL Frontend<br/>React/Next.js]
        E[API Gateway<br/>REST/GraphQL]
        F[AI Service<br/>Python/FastAPI]
    end

    subgraph "Blockchain Layer"
        G[PalCore.sol<br/>Main Contract]
        H[BusinessAccount.sol<br/>User Contracts]
        I[TransactionManager.sol]
        J[ProjectTracker.sol]
    end

    subgraph "Infrastructure Layer"
        K[Base Blockchain<br/>L2 Network]
        L[IPFS/Arweave<br/>File Storage]
        M[The Graph<br/>Indexing]
        N[Chainlink<br/>Oracle Data]
    end

    A --> D
    B --> D
    C --> D
    D --> E
    E --> G
    F --> E
    G --> H
    G --> I
    G --> J
    G --> K
    I --> N
    M -.-> G
```

## Detailed Smart Contract Architecture


```mermaid
classDiagram
    class IPAL {
        <<interface>>
        +enum TransactionType
        +enum ProjectStatus
        +struct BusinessAccountInfo
        +struct Transaction
        +struct Project
        +createBusinessAccount()
        +recordTransaction()
        +addProject()
        +getFinancialSummary()
    }

    class PalCore {
        -address teamWallet
        -uint256 businessCounter
        -mapping businessAccounts
        -mapping businessIdToOwner
        -TransactionManager transactionManager
        -ProjectTracker projectTracker
        +createBusinessAccount()
        +recordTransaction()
        +addProject()
        +updateProjectStatus()
        +getFinancialSummary()
        +getBusinessInfo()
        +emergencyPause()
    }

    class BusinessAccount {
        -uint256 businessId
        -address owner
        -string businessName
        -string businessType
        -uint256 createdAt
        +updateBusinessInfo()
        +getBusinessInfo()
    }

    class TransactionManager {
        -mapping businessTransactions
        -mapping businessBalances
        -mapping totalSales
        -mapping totalExpenses
        +recordTransaction()
        +getFinancialSummary()
        +getTransactionHistory()
        -_checkAlerts()
    }

    class ProjectTracker {
        -mapping businessProjects
        -mapping projectCounters
        +addProject()
        +updateProjectStatus()
        +getProjects()
        +getOverdueProjects()
        -_isProjectOverdue()
    }

    class IBusinessAccount {
        <<interface>>
        +updateBusinessInfo()
        +getBusinessInfo()
    }

    class ITransactionManager {
        <<interface>>
        +recordTransaction()
        +getFinancialSummary()
        +getTransactionHistory()
    }

    class IProjectTracker {
        <<interface>>
        +addProject()
        +updateProjectStatus()
        +getProjects()
        +getOverdueProjects()
    }

    IPAL <|.. PalCore
    IBusinessAccount <|.. BusinessAccount
    ITransactionManager <|.. TransactionManager
    IProjectTracker <|.. ProjectTracker
    
    PalCore --> BusinessAccount : creates
    PalCore --> TransactionManager : manages
    PalCore --> ProjectTracker : manages
    PalCore ..> IPAL : implements
```

## Component Interaction Flow

```mermaid
flowchart TD
    A[User Action] --> B{Action Type}
    B -->|Create Business| C[PalCore.createBusinessAccount]
    B -->|Record Transaction| D[PalCore.recordTransaction]
    B -->|Manage Project| E[PalCore.addProject/updateProjectStatus]
    
    C --> F[Deploy BusinessAccount]
    F --> G[Update Mappings]
    G --> H[Emit BusinessAccountCreated]
    
    D --> I[TransactionManager.recordTransaction]
    I --> J[Update Financial Data]
    J --> K[Check Alert Conditions]
    K --> L{Emit Alerts?}
    L -->|Yes| M[Emit LowBalance/Overspending]
    L -->|No| N[Complete Transaction]
    M --> N
    
    E --> O[ProjectTracker.addProject]
    O --> P[Store Project Data]
    P --> Q[Emit ProjectAdded]
    
    E --> R[ProjectTracker.updateProjectStatus]
    R --> S[Update Status]
    S --> T{Overdue Check}
    T -->|Overdue| U[Emit ProjectOverdue]
    T -->|Not Overdue| V[Complete Update]
    U --> V
    
    H --> W[Frontend Update]
    N --> W
    Q --> W
    V --> W
```

## Storage Architecture

```mermaid
erDiagram
    BUSINESS_ACCOUNT {
        uint256 businessId PK
        address owner
        string businessName
        string businessType
        uint256 createdAt
    }

    TRANSACTION {
        uint256 id PK
        address business FK
        uint256 amount
        string category
        string description
        enum txType
        uint256 timestamp
    }

    PROJECT {
        uint256 id PK
        address business FK
        string clientName
        string projectName
        uint256 amount
        uint256 deadline
        enum status
        uint256 createdAt
    }

    FINANCIAL_SUMMARY {
        address business PK,FK
        uint256 totalSales
        uint256 totalExpenses
        uint256 currentBalance
    }

    BUSINESS_ACCOUNT ||--o{ TRANSACTION : has
    BUSINESS_ACCOUNT ||--o{ PROJECT : has
    BUSINESS_ACCOUNT ||--|| FINANCIAL_SUMMARY : has
```

## Data Flow Architecture

```mermaid
sequenceDiagram
    participant User
    participant Frontend
    participant PalCore
    participant BusinessAccount
    participant TransactionManager
    participant ProjectTracker
    participant Blockchain

    Note over User,Blockchain: Business Creation Flow
    User->>Frontend: Create Business Account
    Frontend->>PalCore: createBusinessAccount()
    PalCore->>BusinessAccount: deploy new contract
    PalCore->>Blockchain: store mappings
    Blockchain-->>PalCore: BusinessAccountCreated event
    PalCore-->>Frontend: success
    Frontend-->>User: business created

    Note over User,Blockchain: Transaction Recording Flow
    User->>Frontend: Record Transaction
    Frontend->>PalCore: recordTransaction()
    PalCore->>TransactionManager: recordTransaction()
    TransactionManager->>Blockchain: update balances
    TransactionManager->>TransactionManager: _checkAlerts()
    Blockchain-->>TransactionManager: LowBalanceAlert (if triggered)
    TransactionManager-->>PalCore: success
    PalCore-->>Frontend: TransactionRecorded event
    Frontend-->>User: transaction recorded

    Note over User,Blockchain: Project Management Flow
    User->>Frontend: Add Project
    Frontend->>PalCore: addProject()
    PalCore->>ProjectTracker: addProject()
    ProjectTracker->>Blockchain: store project data
    Blockchain-->>ProjectTracker: ProjectAdded event
    ProjectTracker-->>PalCore: success
    PalCore-->>Frontend: project added
    Frontend-->>User: project created

    Note over User,Blockchain: Data Query Flow
    User->>Frontend: View Financial Summary
    Frontend->>PalCore: getFinancialSummary()
    PalCore->>TransactionManager: getFinancialSummary()
    TransactionManager-->>PalCore: sales, expenses, profit, balance
    PalCore-->>Frontend: financial data
    Frontend-->>User: display summary
```
# 🛠️ Installation
Prerequisites

- Foundry: curl -L https://foundry.paradigm.xyz | bash

- Node.js (v16+ recommended)

- Base Sepolia ETH for testing

## Setup
```bash

# Clone repository
git clone https://github.com/Nworah-Gabriel/PAL-Contracts

cd pal-contracts

# Install dependencies
forge install

# Build contracts
forge build

# Run tests
forge test
```

## Environment Setup

Create `.env` file and and add the code below to the file

```bash
# Deployment
PRIVATE_KEY=your_private_key_here
TEAM_WALLET=0xYourTeamWalletAddress

# Networks
BASE_MAINNET_RPC=https://mainnet.base.org
BASE_SEPOLIA_RPC=https://sepolia.base.org

# Configuration
DEPLOY_NETWORK=84532

# Verification
ETHERSCAN_API_KEY=your_etherscan_api_key
```

## 🧪 Testing
Comprehensive Test Suite

```bash
# Run all tests
forge test

# Run specific test suites
forge test --match-contract UnitTest
forge test --match-contract IntegrationTest
forge test --match-contract FuzzTest
forge test --match-contract AuditTest

# Run with gas reports
forge test --gas-report

# Run with verbose output
forge test -vvv
```
## Test Coverage

- Unit Tests: Individual contract functionality

- Integration Tests: Cross-contract workflows

- Fuzz Tests: Property-based testing with random inputs

- Audit Tests: Security vulnerability checks

## 🚀 Deployment
### Base Sepolia (Testnet)
```bash

forge script script/DeployPalCore.s.sol:DeployBaseSepolia \
  --rpc-url $BASE_SEPOLIA_RPC \
  --broadcast \
  --verify \
  -vvvv
```
### Base Mainnet
```bash

forge script script/DeployPalCore.s.sol:DeployBaseMainnet \
  --rpc-url $BASE_MAINNET_RPC \
  --broadcast \
  --verify \
  -vvvv
```



## Additional Recommended Files:

### .gitignore
```gitignore
# Dependencies
node_modules/
lib/

# Build artifacts
out/
cache/
broadcast/

# Environment files
.env
.env.local
.env.production

# IDE
.vscode/
.idea/

# OS
.DS_Store
Thumbs.db

# Logs
*.log
```


## 📄 License
This project is licensed under the [MIT License](https://en.wikipedia.org/wiki/MIT_License) - see the [LICENSE file](./LICENSE) for details.