## 03-lottery
This project creates a Lottery contract where participants pay a fee to be randomly picked as a winner from a pool of participants.
1. The admin is the contract deployer. 
2. Participants must sent .1 ETH to be added to pool.
3. Once there are at least 2 participants the admin  can call the *pickWinner* function. A a random number determines the winner, and the balance accumulated goes to winning participant's address.
NOTES: Random number generation can be improved by leveraging resources available on different blockchains, notably Chainlink's VRF.