# My ERC-721 implementation

This project is my first attempt at implementing the [ERC-721 non-fungible token standard](https://eips.ethereum.org/EIPS/eip-721). I worked on this for about 3-4 days. The only prior experience with blockchain devleopment I have had up until this point was [MislavCoin](https://github.com/MislavJuric/MislavCoin). My goal was to try to implement the aforementioned standard without looking at any existing implementation. I'm publishing what I've coded up until the point where I got stuck and where I would take a look at an existing implementation.

You can find my implementation in the **contracts** folder.

This project taught me that I should familiarize myself with smart contract design patterns. In particular, I seem to be fond of doing things with for loops, which is an anti-pattern in smart contract development because of the gas costs associated with iterating over a large array. This is an area I can improve upon.

After looking at [OpenZeppelin's ERC-721 implementation](https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC721/ERC721.sol), I noticed that I could have done the following things better:

- put repeated checks into their own methods
- used hooks

**Important note**: I *do* know how to use blockchain development tools, write tests, deploy contracts etc. For a more comprehensive project of mine, visit [MislavCoin](https://github.com/MislavJuric/MislavCoin).
