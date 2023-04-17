# Randomness

## Intent

Generate a random number of a predefined interval in the deterministic environment of a blockchain. 

在区块链的确定性环境中生成预定义区间内的随机数。

## Motivation

Randomness in computer systems and especially in Ethereum is notoriously difficult to achieve. While it is hard or even impossible to generate a truly random number via software, the need for randomness in Ethereum is high. This stems from the fact that a high percentage of smart contracts on the Ethereum blockchain can be classified as games, which often rely on some kind of randomness to determine a winner. The problem with randomness in Ethereum is that Ethereum is a deterministic Turing machine, with no inherent randomness involved. A majority of miners have to obtain the same result when evaluating a transaction to reach consensus. Consensus is one of the pillars of blockchain technology and randomness would imply that mutual agreement between all nodes is impossible. Another problem is the public nature of a blockchain. The internal state of a contract, as well as the entire history of a blockchain, is visible to the public. Therefore, it is difficult to find a secure source of entropy. One of the first sources of randomness in Ethereum that came to mind were block timestamps. The problem with block timestamps is, that they can be influenced by the miner, as long as the timestamp is not older than its parent block. Most of the time the timestamps will be close to correct, but if a miner has an incentive to benefit from wrong timestamps, he could use his mining power, in order to mine his blocks with incorrect timestamps to manipulate the outcome of the random function to his favor.

Several workarounds have been developed that overcome this limitations in one way or the other. They can be differentiated into the following groups, each with their respective benefits and downsides:

* **Block hash PRNG** - the hash of a block as source of randomness
* **Oracle RNG** - randomness provided by an oracle, see [Oracle pattern](./oracle.md)
* **Collaborative PRNG** - collaborative generation of a random number within the blockchain

Because the use of an oracle has already been discussed in the [respective pattern](./oracle.md) and the most renown example of collaborative PRNG, [Randao](https://github.com/randao/randao), is not being actively developed anymore, we will focus on the generation of pseudorandom numbers with the help of block hashes in this chapter. Considerations between the use of oracle RNG versus block hash PRNG will be discussed in the Consequences section.


计算机系统中，尤其是以太坊中的随机性通常很难实现。虽然通过软件生成真正的随机数很难甚至不可能，但在以太坊中需要随机性的需求很高。这是由于以太坊区块链上高比例的智能合约可以被归类为游戏，这些游戏通常依赖某种随机性来决定赢家。以太坊中随机性的问题在于，以太坊是一个确定性图灵机，没有内在的随机性。大多数矿工必须在评估交易时获得相同的结果以达成共识。共识是区块链技术的支柱之一，而随机性意味着所有节点之间的相互协议是不可能的。另一个问题是区块链的公开性质。合约的内部状态以及整个区块链的历史记录对公众都是可见的。因此，要找到一个安全的熵源是很困难的。最早想到的以太坊随机性来源之一是块时间戳。块时间戳的问题在于，只要时间戳不早于其父块，就可以被矿工影响。大部分时间时间戳会接近正确，但如果矿工有动机从错误的时间戳中获益，他可能会利用自己的挖矿能力，以不正确的时间戳挖掘自己的区块以操纵随机函数的结果。

已经开发了几种解决这些限制的解决方案。它们可以分为以下几组，每组都有其各自的优缺点：

* **块哈希 PRNG** - 块的哈希作为随机数的来源
* **预言机 RNG** - 预言机提供的随机性，详见预言机模式
* **协同 PRNG** - 在区块链内协同生成随机数

因为在相应模式中已经讨论了使用预言机的情况，并且最著名的协同 PRNG [Randao](https://github.com/randao/randao) 已经不再被积极开发，因此在本章中将重点讨论利用块哈希生成伪随机数的方法。使用预言机 RNG 或块哈希 PRNG 的考虑将在后续影响部分中进行讨论。


## Applicability

Use the Randomness pattern when

* you want to generate a random number that is not predictable by the users.
* you do not want to use any external services for randomness.
* you have a trusted entity that is able to reliably provide seeds for the generation of randomness.


当以下情况时，使用随机性模式：

* 您想生成一个用户无法预测的随机数。
* 您不想使用任何外部服务来实现随机性。
* 您有一个可信赖的实体，能够可靠地提供用于生成随机数的种子。

## Participants & Collaborations

The participating entities in this pattern are the calling contract, a trusted entity and a miner, mining the block of which we are using the block hash as source of entropy. The contract makes use of the  globally available variable of the hash of a block and uses it together with a seed, provided by the trusted entity, to internally compute a number that should be unknown to anyone until the block is mined.

此模式中的参与实体包括调用合约、一个可信实体和一个挖掘矿块的矿工。我们使用块哈希作为熵源。合约利用全局可用的块哈希变量，并与由可信实体提供的种子一起内部计算一个数字，该数字在挖掘块之前应该对任何人都是未知的。

## Implementation

The simplest implementation of this pattern would be just using the most recent block hash:

```Solidity
// Randomness provided by this is predicatable. Use with care!
function randomNumber() internal view returns (uint) {
    return uint(blockhash(block.number - 1));
}
```

Implemented like this there are two problems, making this solution impractical:

1. a miner could withhold a found block, if the random number derived from the block hash would be to his disadvantage. By withholding the block, the miner would of course lose out on the block reward. This problem is therefore only relevant in cases the monetary value relying on the random number is at least comparatively high as the current block reward.
2. the more concerning problem is that since `block.number` is a variable available on the blockchain, it can be used as an input parameter by any user. In case of a gambling contract, a user could use `uint(blockhash(block.number - 1)` as the input for his bet and always win the game.

To get rid of the possibility of interference by miners and prediction of random numbers, Bonneau et al. proposed a solution applied on the Bitcoin blockchain \cite{cryptoeprint:2015:1015}: a trusted party provides a seed, which will be hashed together with a future block hash, to make it impossible for the miner to predict the outcome of his block hash on the random number. We are using this idea in this pattern to avoid interference by malicious miners.

The trusted party can be chosen by the contract creator and is stored in the contract. In the beginning users can make their interaction with the contract (like placing bets) in the first stage. With the submission of the sealed seed by the trusted party, bets are closed and the current block number + 1 is stored, which will come in handy later. The seed can be sealed by hashing it together with the address of the trusted party. This allows for easy validation in the next step.

After the seed has been stored, the trusted party has to wait for at least one block until it can reveal the seed. Of course it has to be validated, that the committed hash was the result of a hash of the now provided seed, by comparing the sealed seed with the hash of the actual seed and the address of the trusted party. If this is the case, the seed is accepted and can be hashed together with the stored block number to generate a pseudorandom number. We use the block number stored in the previous step, because using the current block number would allow for interference by withholding from the miner again, as the seed is sent in plaintext. With the incrementation the block number before storing it, we are making sure a future block hash is used as source of entropy, making it impossible for the trusted party to predict it.

In case the random number is supposed to be of a special interval, the modulo function can be utilized. Depending on the desired length, only the last part of the obtained hash is used.

这种模式的最简单实现方式就是只使用最新的块哈希：

```Solidity
// 此种方式提供的随机数是可预测的，需谨慎使用！
function randomNumber() internal view returns (uint) {
    return uint(blockhash(block.number - 1));
}
```

这样实现存在两个问题，导致该解决方案不切实际：

1. 如果从块哈希派生的随机数对于矿工来说是不利的，他可以扣留已找到的块。当然，矿工会失去块奖励。因此，只有在依赖随机数的货币价值至少与当前块奖励相当高的情况下，此问题才是相关的。
2. 更为令人担忧的问题是，由于 `block.number` 是区块链上可用的变量，任何用户都可以将其用作输入参数。在赌博合约的情况下，用户可以将 `uint(blockhash(block.number - 1)` 用作他的赌注输入，从而总是赢得游戏。

为了消除矿工干扰和随机数预测的可能性，Bonneau等人提出了一种在比特币区块链上应用的解决方案。该方案是**由可信方提供一个种子，并将其与未来的块哈希一起哈希，以使矿工无法预测其块哈希对随机数的影响结果**。在这个模式中，我们使用这个想法来避免恶意矿工的干扰。

可信方可以由合约创建者选择并存储在合约中。在开始阶段，用户可以进行与合约的交互（如下注）。随着可信方提交封闭的种子，下注将被关闭，并存储当前块数 + 1，这将在后面派上用场。种子可以通过将其与可信方地址一起哈希来封存。这样做可以在下一步轻松验证。

种子存储后，可信方必须等待至少一个块才能揭示种子。当然，必须验证提交的哈希结果是由现提供的种子哈希得出的，通过比较封存的种子与实际种子的哈希和可信方地址。如果是这样，种子就被接受，并可与存储的块号一起哈希以生成伪随机数。我们使用上一步存储的块号，因为使用当前块号将允许矿工再次扣留，因为种子是以明文形式发送的。通过在存储之前增加块号的增量，我们确保使用未来的块哈希作为熵源，使得可信方无法预测它。

如果要求得到特定区间的随机数，则可以利用模函数。根据所需的长度，只使用获得的哈希的最后部分即可。

## Sample Code

The provided sample showcases the implementation of a pseudorandom number generator with the use of a trusted entity in the context of a betting contract. Any logic regarding the betting process is omitted for the sake of clarity.

```Solidity
contract Randomness {

    bytes32 sealedSeed;
    bool seedSet = false;
    bool betsClosed = false;
    uint storedBlockNumber;
    address trustedParty = 0xdCad3a6d3569DF655070DEd06cb7A1b2Ccd1D3AF;

    function setSealedSeed(bytes32 _sealedSeed) public {
        require(!seedSet);
        require (msg.sender == trustedParty);
        betsClosed = true;
        sealedSeed = _sealedSeed;
        storedBlockNumber = block.number + 1;
        seedSet = true;
    }

    function bet() public {
        require(!betsClosed);
        // Make bets here
    }

    function reveal(bytes32 _seed) public {
        require(seedSet);
        require(betMade);
        require(storedBlockNumber < block.number);
        require(keccak256(msg.sender, _seed) == sealedSeed);
        uint random = uint(keccak256(_seed, blockhash(storedBlockNumber)));
        // Insert logic for usage of random number here;
        seedSet = false;
        betsClosed = false;
    }
}
```

The trusted party is hard-coded into the contract in line 7. It would be an option to allow for the change of the trusted party by the owner with the help of a setter function protected against unauthorized access by the [Access Restriction pattern](./access_restriction.md). Users can make their bets by calling the function `bet()`. The hashed seed can be set by the trusted party, and only the trusted party (line 11), by calling `setSealedSeed(bytes32 _sealedSeed)`. With the function execution, the sealed seed as well as the incremented current block number is stored and the `seedSet` boolean is set to true, to avoid the seed being overwritten by a second function call. Additionally bets are closed, to avoid that the trusted party or the miner can push their bets after learning about the seed or the block hash used to generate the random number.

After at least one block has passed after providing the sealed seed, the trusted entity can reveal the seed by calling `reveal(bytes32 _seed)` in line 23. The lines 24-27 implement the [Guard Check pattern](./guard_check.md) and assure that the seed can only be revealed after the sealed seed was set (line 24), the relying action has been performed (line 25) and the block we are referencing has already been mined (line 26). An access restriction for the trusted party could be implemented, but is not mandatory, as the trusted party should be the only entity that can provide a seed which matches the sealed seed. This is verified in line 27, where it is checked , if the seed provided by the trusted party was indeed the same, as the one committed in the step before. The actual random number is generated in line 28 by hashing the seed together with the hash of the block at the previously stored number. Next steps could be the formatting of the number into the desired interval and the execution of any logic using the random number, like the payout of the winners.

提供的样例展示了在一个投注合约的上下文中，如何使用可信实体实现伪随机数生成器。为了清晰起见，与投注过程相关的任何逻辑都被省略了。

这是一个 Solidity 合约，其实现伪随机数生成器的代码如下。可信实体在第7行中被硬编码到合约中。允许合约所有者使用受到访问限制的设置器函数更改可信实体，以便更好地保护其安全性。用户可以通过调用 `bet()` 函数来下注。可信实体可以通过调用 `setSealedSeed(bytes32 _sealedSeed)` 函数来设置哈希种子，且只有可信实体有权进行此操作（第11行）。在函数执行期间，密封的种子以及增加的当前块编号被存储，并将 `seedSet` 布尔值设置为 true，以避免种子被第二个函数调用覆盖。此外，关闭了下注，以避免可信实体或矿工在了解有关生成随机数所使用的种子或块哈希后推送其下注。

在提供密封种子后至少经过一个区块后，可信实体可以通过调用 `reveal(bytes32 _seed)` 函数（第23行）来公开种子。第24-27行实现了 Guard Check 模式，并确保只有在设置了密封种子（第24行），已执行了依赖操作（第25行）且我们引用的区块已经被挖掘（第26行）后，才能公开种子。对于可信实体的访问限制可以实现，但并不是强制的，因为可信实体应该是能够提供与密封种子匹配的种子的唯一实体。这在第27行进行了验证，即检查可信实体提供的种子是否确实与之前提交的种子相同。在第28行生成实际的随机数，通过将种子与先前存储的块号的哈希值进行哈希运算得到。接下来的步骤可能包括将数字格式化到所需的区间，并使用随机数执行任何逻辑，例如支付赢家的奖金。


## Consequences

The consequences of the Randomness Pattern can be evaluated after the following criteria inspired by Kofler (2016):

* **Randomness** - how good is the achieved randomness? Is it pseudo or true randomness?
* **Security** - how secure is the used method to generate randomness?
* **Cost** -  how high are the costs associated with generating randomness?
* **Delay** - how big is the time delay between request and reception of the random number?

The **randomness** generated by the proposed method is pseudorandom. The block hash as well as the seed are provided in a deterministic way and if both input parameters were known, the result could be predicted. However, due to the combination of block hash and seed from two different sources, and both sources having to commit their inputs before learning of the other, it is practically impossible to influence the random number for your benefit.

Once a random number is obtained, we can assume that it is **secure**. The only form of insecurity is introduced by the trusted party. The name trusted party does not mean that we have to trust the party blindly. On the contrary, the measures taken, make it impossible to manipulate the random number, even for the trusted party. We only have to trust it to reveal the provided seed. As the seed is sealed in a cryptographically secure way, there is currently no possibility to obtain the seed without the trusted party. Additionally, the Ethereum blockchain only allows access to the 256 most recent blocks, meaning that the trusted entity has to reveal the seed before the stored block number is not retrievable anymore. A revert mechanism for this case, which lets the users retrieve their funds, should be implemented. In summary that means, that the only way of cheating, with this pattern implemented, would be for the trusted party to withhold the revealed seed, or if the trusted party could influence the block creation of the block of which we are using the hash (either by mining itself or colluding with miners). Nevertheless, this is an improvement over the previous solution, as there is now only one single potential threat, compared to several miners as before.

The **costs** of this method are relatively low, as no external service has to be payed. The gas requirements using a trusted entity are higher, compared to the simple case, as more transactions and storage is needed.

Due to the commitment to a seed and the use of a future block hash, the generation of the random number comes with a little **delay**. In the fastest case a result can be expected after two blocks.

When we compare these consequences with the ones of the [Oracle pattern](./oracle.md), we can work out their differences. The randomness provided by the Oracle can be true randomness, as we can query numbers from services providing true random numbers. While we only have to trust one party in our example, two parties have to be trusted when interacting with oracles: the data provider as well as the oracle service. Another difference is that the oracle service has to be paid for each request. The delay experienced with the oracle solution is comparable to the one proposed above.

It can be concluded, that in simple contracts with no financial impact, a simple implication of block hash randomness without a seed is sufficient. For use cases with higher stakes an oracle service or the showcased solution with a seed can be used, depending on the trust one is willing to put into other parties.


随机性模式的后果可以按照 Kofler（2016）提出的以下标准进行评估：

* **随机性** - 实现的随机性有多好？它是伪随机还是真随机？
* **安全性** - 用于生成随机性的方法有多安全？
* **成本** - 生成随机数的成本有多高？
* **延迟** - 请求和接收随机数之间的时间延迟有多大？

所提出的方法生成的随机数是伪随机的。块哈希以及种子以确定性的方式提供，如果两个输入参数都已知，则可以预测结果。然而，由于组合了来自两个不同来源的块哈希和种子，并且两个来源都必须在了解另一个输入之前提交它们的输入，因此在实践中几乎不可能为了自己的利益影响随机数。

一旦获得随机数，我们可以假设它是**安全**的。唯一的不安全性是由可信实体引入的。可信实体的名称并不意味着我们必须盲目地信任该实体。相反，采取的措施使得即使是可信实体也无法操纵随机数。我们只需要信任它公开提供的种子。由于种子以加密安全的方式封存，目前没有可能在没有可信实体的情况下获得种子。此外，以太坊区块链只允许访问最近的256个区块，这意味着可信实体必须在存储的块号无法再检索之前公开种子。应该为这种情况实现一种还原机制，让用户检索他们的资金。总之，意味着在实现这种模式时作弊的唯一方法是可信实体不公开种子，或者如果可信实体能够影响我们使用哈希的块的块创建（通过自己挖矿或与矿工勾结）。尽管如此，与之前的解决方案相比，这是一种改进，因为现在只有一个潜在的威胁，而不是以前的几个矿工。

这种方法的**成本**相对较低，因为不需要支付外部服务费用。与简单情况相比，使用可信实体的 gas 要求更高，因为需要更多的交易和存储。

由于对种子的承诺和对未来块哈希的使用，生成随机数会带来一些 **延迟** 。在最快的情况下，预计在两个块之后可以得出结果。

当我们将这些后果与 Oracle 模式 的后果进行比较时，我们可以发现它们的差异。Oracle 提供的随机性可以是真随机性，因为我们可以从提供真随机数的服务中查询数字。在我们的示例中，只需要信任一个方，而与 Oracle 交互时必须信任两个方：数据提供者和 Oracle 服务。另一个区别是，每次请求都必须支付 Oracle 服务的费用。使用 Oracle 时经历的延迟与上面提出的解决方案相当。

可以得出结论，在没有财务影响的简单合约中，仅使用块哈希随机性而不使用种子就足够了。对于风险更大的用例，可以使用 Oracle 服务或具有种子的展示解决方案，具体取决于愿意将信任放在其他方面的程度。

## Known Uses

Randomness is often used in contracts with a gaming or gambling context. Implementation of randomness via a future block hash and a seed can be observed in the [Cryptogs contract](https://etherscan.io/address/0xeFabE332D31c3982B76F8630a306C960169bD5b3\#code), a DApp that provides a version of the game of pogs on the Ethereum blockchain. A commit/reveal scheme is used to avoid the use of an oracle. However, [they claim](https://medium.com/coinmonks/is-block-blockhash-block-number-1-okay-14a28e40cc4b) that the added security, compared to a simpler implementation without a commit/reveal mechanic is not worth it for their use case. The additional time and costs related to the extra transactions is not in relation to the monetary value they are handling.

Even though trust is an issue, a lot of contracts seem to be using the services of oracles to access random numbers. All of the observed ones were using Oraclize as their service. The actual source of randomness that Oraclize is getting its numbers from is more heterogeneous. An example for a contract using Oraclize in combination with random.org is [vDice](https://etherscan.io/address/0x7DA90089A73edD14c75B0C827cb54f4248D47eCc\#code), which claims  to be the most popular Ether betting game with over 70.000 bets played. Another contract relying on the services of Oraclize is [Pray4Prey](https://etherscan.io/address/0xe648ae88a6d9b3373e115e3414be91b7cf12de4c\#code). In contrast to vDice, random numbers are generated at WolframAlpha.

The general impression is that simpler contracts tend to rely on block hashes and therefore avoid external communications, while more sophisticated contracts and the ones dealing with larger stakes seem to be more likely to use the services of oracles.

随机性常常被用在具有游戏或赌博背景的合同中。通过未来块哈希和种子实现随机性的方式可以在 Cryptogs 合同中被观察到，这是一个在以太坊区块链上提供 pogs 游戏版本的 DApp。该合同使用提交/揭示方案来避免使用预言机。然而，他们声称相对于没有提交/揭示机制的更简单的实现，增加的安全性对于他们的使用情况来说不值得。额外的时间和与额外交易相关的成本与他们正在处理的货币价值不成比例。

尽管信任是一个问题，但许多合同似乎在使用预言机的服务来访问随机数。所有被观察到的合同都使用 Oraclize 作为其服务。Oraclize 获得其数字的实际来源更为多样化。一个使用 Oraclize 与 random.org 结合的合同示例是 vDice，它声称是 Ether 下注游戏中最受欢迎的游戏之一，已经进行了超过 70,000 次下注。另一个依赖于 Oraclize 服务的合同是 Pray4Prey。与 vDice 不同，随机数是在 WolframAlpha 生成的。

一般的印象是，更简单的合同往往依赖于块哈希，因此避免了外部通信，而更复杂的合同和处理更大赌注的合同似乎更有可能使用预言机的服务。


[**< Back**](https://fravoll.github.io/solidity-patterns/)
