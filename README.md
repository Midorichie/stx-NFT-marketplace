# Stacks NFT Marketplace Smart Contract

A decentralized NFT (Non-Fungible Token) marketplace built on the Stacks blockchain using Clarity smart contracts. This marketplace enables users to create, list, buy, sell, and trade NFTs with features like royalties, bidding, and transaction history.

## Features

### Core Functionality
- Create and mint new NFTs with metadata
- List NFTs for sale with customizable prices and expiry times
- Purchase listed NFTs
- Built-in royalty system for original creators
- Offer/bidding system for NFTs
- Comprehensive transaction history tracking

### Security Features
- Contract pause functionality for emergency situations
- Token locking mechanism during active listings
- Royalty enforcement
- Ownership verification
- Expiry validation
- Secure payment handling

### Administrative Features
- Adjustable marketplace fees
- Contract pause/unpause capability
- Transaction monitoring

## Technical Details

### Contract Structure

```clarity
# Main Data Structures
- tokens: Stores NFT ownership and metadata
- listings: Manages active sale listings
- token-offers: Handles bidding system
- transaction-history: Tracks all NFT transactions
```

### Core Functions

#### NFT Creation
```clarity
(mint (metadata-url (string-ascii 256)) (royalty-percentage uint))
```
- Creates new NFT with specified metadata URL
- Sets royalty percentage for future sales
- Records creation in transaction history

#### Listing Management
```clarity
(list-token (token-id uint) (price uint) (expiry uint))
```
- Lists NFT for sale with specified price and expiry
- Locks token during active listing
- Validates ownership and listing parameters

#### Purchase Processing
```clarity
(purchase-token (listing-id uint))
```
- Processes NFT purchase
- Handles royalty distribution
- Updates ownership and listing status
- Records transaction in history

#### Offer System
```clarity
(make-offer (token-id uint) (price uint) (expiry uint))
(accept-offer (token-id uint) (buyer principal))
```
- Enable bidding on NFTs
- Process offer acceptance and NFT transfer

## Setup and Deployment

### Prerequisites
- Stacks blockchain development environment
- Clarinet for local testing
- Basic understanding of Clarity smart contracts

### Installation
1. Clone the repository
2. Install dependencies:
   ```bash
   clarinet install
   ```
3. Run tests:
   ```bash
   clarinet test
   ```

### Deployment
1. Update contract configurations if needed
2. Deploy using Clarinet:
   ```bash
   clarinet deploy
   ```

## Usage Examples

### Creating an NFT
```clarity
;; Mint new NFT
(contract-call? .nft-marketplace mint "https://metadata-url.com" u25)
```

### Listing an NFT
```clarity
;; List NFT for sale
(contract-call? .nft-marketplace list-token u1 u1000000 u100)
```

### Making an Offer
```clarity
;; Make offer for NFT
(contract-call? .nft-marketplace make-offer u1 u900000 u50)
```

### Purchasing an NFT
```clarity
;; Purchase listed NFT
(contract-call? .nft-marketplace purchase-token u1)
```

## Error Codes

- `u100`: Owner-only operation
- `u101`: Not token owner
- `u102`: Listing expired
- `u103`: Price mismatch
- `u104`: Invalid metadata
- `u105`: Listing not found
- `u106`: NFT locked
- `u107`: Insufficient balance
- `u108`: Already listed

## License
MIT License

## Contributing
1. Fork the repository
2. Create feature branch
3. Commit changes
4. Push to branch
5. Create Pull Request

## Security

### Audit Status
- Initial security review completed
- Regular audits recommended before major updates

### Known Limitations
- Maximum transaction history of 10 entries per token
- Fixed marketplace fee structure (requires contract update to change)
- No support for batch operations

## Future Improvements
1. Batch minting and listing capabilities
2. Enhanced metadata validation
3. Dynamic marketplace fees based on token value
4. Secondary market royalty adjustments
5. Integration with external price feeds
6. Enhanced offer management system

## Support
For support, please open an issue in the repository or contact the maintainers.

## Acknowledgments
- Stacks Foundation
- Clarity Smart Contract Community
- NFT Standard Contributors