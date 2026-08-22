## 02-token-exchange
This project creates a Trust contract where a Parent can lock tokens to be released to a Kid after a set amount of time.
Contract features:

1. Contract is initialized with a Kid object, and Parent as owner/initial msg.sender.
2. Parent adds kid(s) to array based on their address, with *amount* and *maturity* parameters.
3. Maturity is based on block.timestamp.
4. Parent can cancel trust at any point during maturity, refunding tokens back to their wallet.
5. After maturation, the Kid can withdraw the locked tokens to their wallet.

NOTES: This contract has been updated from the coursework to reflect current contract safeguards, such as payable function calls and Reentrancy Guard.