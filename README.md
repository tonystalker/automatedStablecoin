# **Algorithmic Stablecoin Smart Contract - README**

## **Overview**

This smart contract implements an algorithmic stablecoin that **automatically maintains its peg to 1 USD** by adjusting the token supply based on **real-time price data** from the **Pyth Network**. The contract follows an elastic supply model, adjusting supply when the token price deviates beyond the defined tolerance band.

## **Core Mechanisms**

### **1. Price Stability**

- **Target Price**: Pegged to **1 USD**, represented as `1e18 wei` (due to 18 decimal precision in Solidity).
- **Tolerance Band**: Allows for a **±1% tolerance** around the target price. Price deviations within this band will not trigger supply adjustments.
- **Maximum Supply Adjustment**: Capped at **5%** per adjustment to avoid excessive supply volatility.
- **Cooldown Period**: A mandatory cooldown of **1 hour** between adjustments to prevent rapid supply changes.

### **2. Supply Control**

- **Above Peg**: When the price exceeds **$1.01** (above tolerance), the contract **burns tokens** to reduce supply and stabilize the price.
  - **Adjustment Size**: Proportional to the price deviation.
- **Below Peg**: When the price drops below **$0.99** (below tolerance), the contract **mints tokens** to increase supply and stabilize the price.
  - **Adjustment Size**: Proportional to the price deviation.

### **3. Price Oracle**

- Uses the **Pyth Network** for real-time price feeds.
- Price updates must be triggered using the **`updatePriceAndAdjustSupply()`** function.
- **Regular price updates** are required to maintain supply adjustments based on accurate data.

## **Security Features**

### **1. Access Control**

- **STABILIZER_ROLE**: Responsible for minting/burning tokens and calling supply adjustment functions.
- **DEFAULT_ADMIN_ROLE**: Administrative control for assigning roles and managing contract settings.

### **2. Safety Mechanisms**

- **Pausable**: Contract can be **paused in emergencies**, halting all minting, burning, and price update operations.
- **Cooldown Period**: **1-hour cooldown** between adjustments prevents rapid supply changes.
- **Capped Adjustment Size**: Supply adjustments are capped at **5%** to limit volatility.
- **Tolerance Band**: Prevents unnecessary adjustments when the price is within **±1% of the peg**.

## **Deployment Instructions**

1. **Configure network** in `hardhat.config.js`.
2. **Set Pyth Network address** and price feed ID in the deployment script.
3. Deploy using the following command:

   ```bash
   npx hardhat run scripts/deploy.js --network <network_name>
   ```

## **Testing**

### **Local Testing**:

Run the following command to test the contract locally:

```bash
npx hardhat test
```
