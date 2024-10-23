// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@pythnetwork/pyth-sdk-solidity/IPyth.sol";
import "@pythnetwork/pyth-sdk-solidity/PythStructs.sol";

/**
  @title automatedStablecoin
  @notice An automated stablecoin that maintains its peg through supply adjustments
  @dev Used Pyth Network for price feeds
 */
contract automatedStablecoin is ERC20, AccessControl, Pausable {
    bytes32 public constant STABILIZER_ROLE = keccak256("STABILIZER_ROLE");
    
    // Pyth Network integration
    IPyth public pyth;
    bytes32 public priceId; 
    
    // Stability parameters
    uint256 public constant TARGET_PRICE = 1e18;  // Target price of 1 USD in wei
    uint256 public constant PRICE_TOLERANCE = 1e16;  // 1% tolerance band
    uint256 public constant MAX_SUPPLY_ADJUSTMENT = 5e16;  // 5% max supply adjustment
    
    // Cooldown period between adjustments
    uint256 public constant ADJUSTMENT_COOLDOWN = 1 hours;
    uint256 public lastAdjustmentTime;
    
    // Events
    event SupplyAdjusted(uint256 currentPrice, uint256 targetPrice, int256 adjustment);
    event PriceUpdated(uint256 newPrice);
    
    constructor(
        address _pythAddress,
        bytes32 _priceId
    ) ERC20("CentCoin", "Cent") {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(STABILIZER_ROLE, msg.sender);
        
        pyth = IPyth(_pythAddress);
        priceId = _priceId;

        
        _mint(msg.sender, 1000000 * 10**decimals());
    }
    
    /**
     * @notice Updates price feed and adjusts supply if needed
     * @param pythUpdateData The Pyth price update data
     */
    function updatePriceAndAdjustSupply(bytes[] calldata pythUpdateData) external whenNotPaused {
        require(
            block.timestamp >= lastAdjustmentTime + ADJUSTMENT_COOLDOWN,
            "Adjustment cooldown not met"
        );
        
        // Update Pyth price feed
        pyth.updatePriceFeeds{value: pyth.getUpdateFee(pythUpdateData)}(pythUpdateData);
        
        // Get latest price
        PythStructs.Price memory priceData = pyth.getPrice(priceId);
        uint256 currentPrice = uint256(int256(priceData.price));
        
        emit PriceUpdated(currentPrice);
        
        // Check if price is outside tolerance band
        if (isPriceOutsideTolerance(currentPrice)) {
            adjustSupply(currentPrice);
        }
        
        lastAdjustmentTime = block.timestamp;
    }
    
    /**
     * @notice Checks if current price is outside tolerance band
     * @param currentPrice The current price from Pyth
     * @return bool True if price is outside tolerance
     */
    function isPriceOutsideTolerance(uint256 currentPrice) public pure returns (bool) {
        return (
            currentPrice > TARGET_PRICE + PRICE_TOLERANCE ||
            currentPrice < TARGET_PRICE - PRICE_TOLERANCE
        );
    }
    
    /**
     * @notice Adjusts token supply based on price deviation
     * @param currentPrice The current price from Pyth
     */
    function adjustSupply(uint256 currentPrice) internal {
        int256 priceDeviation = int256(currentPrice) - int256(TARGET_PRICE);
        uint256 totalSupply = totalSupply();
        
        // Calculate adjustment percentage (capped at MAX_SUPPLY_ADJUSTMENT)
        uint256 adjustmentPercentage = calculateAdjustmentPercentage(currentPrice);
        uint256 adjustmentAmount = (totalSupply * adjustmentPercentage) / 1e18;
        
        if (priceDeviation > 0) {
            // Price is too high - burn tokens
            _burn(address(this), adjustmentAmount);
        } else {
            // Price is too low - mint tokens
            _mint(address(this), adjustmentAmount);
        }
        
        emit SupplyAdjusted(currentPrice, TARGET_PRICE, priceDeviation);
    }
    
    /**
     * @notice Calculates the percentage of supply to adjust
     * @param currentPrice The current price from Pyth
     * @return uint256 The adjustment percentage in wei
     */
    function calculateAdjustmentPercentage(uint256 currentPrice) public pure returns (uint256) {
        uint256 deviation = currentPrice > TARGET_PRICE ?
            currentPrice - TARGET_PRICE :
            TARGET_PRICE - currentPrice;
            
        uint256 adjustmentPercentage = (deviation * 1e18) / TARGET_PRICE;
        return adjustmentPercentage > MAX_SUPPLY_ADJUSTMENT ?
            MAX_SUPPLY_ADJUSTMENT :
            adjustmentPercentage;
    }
    
    /**
     * @notice Allows admin to pause supply adjustments
     */
    function pause() external onlyRole(DEFAULT_ADMIN_ROLE) {
        _pause();
    }
    
    /**
     * @notice Allows admin to unpause supply adjustments
     */
    function unpause() external onlyRole(DEFAULT_ADMIN_ROLE) {
        _unpause();
    }
    
    // Required for receiving ETH (needed for Pyth updates)
    receive() external payable {}
}