# Tight Variable Packing

## Intent

Optimize gas consumption when storing or loading statically-sized variables.

在存储或加载静态大小变量时，优化gas消耗。

## Motivation

As with all patterns in this category the main goal of implementing them is the reduction of gas requirement. This pattern in special is easily applied and does not change any contract logic. All that has to be done is writing suitable state variables in the correct order. To reduce the amount of gas used for deploying a contract, and later on calling his functions, we make use of the way the EVM allocates storage. Storage in Ethereum is a key-value store with keys and values of 32 bytes each. When storage is allocated, all statically-sized variables (everything besides mappings and dynamically-sized arrays) are written down one after another, in the order of their declaration, starting at position 0. The most commonly used data types (e.g. `bytes32`, `uint`, `int`) take up exactly one 32 byte slot in storage. This pattern describes how to save gas by using smaller data types (e.g. `bytes16`, `uint32`) when possible, as the EVM can then pack them together in one single 32 byte slot and therefore use less storage. Gas is then saved because the EVM can combine multiple reads or writes into one single operation. The underlying behavior is also referred to as "tight packing" and is unfortunately, until the time of writing, not automatically achieved by the optimizer.

与此类别中的所有模式一样，实现它们的主要目标是减少gas需求。这种模式特别容易应用，不会改变任何合约逻辑。需要做的只是以正确的顺序编写适当的状态变量。为了减少部署合约和调用其函数时使用的gas量，我们利用了EVM分配存储空间的方式。以太坊中的存储是一个键值存储，其中每个键和值都是32字节。当存储被分配时，所有静态大小变量（除了映射和动态大小数组之外的所有内容）按照它们的声明顺序依次写入，从位置0开始。最常用的数据类型（例如 `bytes32`，`uint`，`int`）在存储中占用一个32字节的槽位。该模式描述了如何通过在可能的情况下使用较小的数据类型（例如 `bytes16`，`uint32`）来节省gas，因为EVM可以将它们打包在一个单独的32字节槽中，从而使用更少的存储空间。由于EVM可以将多个读取或写入组合成一个单独的操作，因此可以节省gas。该模式的基本行为也称为“紧密打包”，但不幸的是，在撰写本文时，优化器还没有自动实现该行为。

## Applicability

Use the Tight Variable Packing pattern when

* you want to reduce contract interaction costs.
* you are using more than one statically-sized state variable and can afford to use variables of smaller sizes.
* you are using a struct consisting of more than one variable and can afford to use variables of smaller sizes.
* you are using a statically-sized array and can afford to use a variable of a smaller size.

当满足以下条件时，可以使用“紧密变量打包”模式：

* 想要减少合约交互成本。
* 使用多个静态大小的状态变量，并且可以使用较小大小的变量。
* 使用由多个变量组成的结构体，并且可以使用较小大小的变量。
* 使用静态大小的数组并可以使用较小大小的变量。

## Participants & Collaborations

In general, the only participant in this pattern is the contract implementing it. All other entities interacting with said contract will not be influenced in any way, as the changes only affect how data gets stored.

一般来说，此模式的唯一参与者是实现该模式的合约。所有与该合约交互的其他实体不会受到任何影响，因为更改只会影响数据的存储方式。

## Implementation

As hinted in the Applicability section, this pattern can be used for state variables, inside structs and for statically-sized arrays. The implementation of this pattern is quite straight forward and can be separated into two tasks:

1. Using the smallest possible data type that still guarantees the correct execution of the code. For example postal codes in Germany have at most 5 digits. Therefore, the data type `uint16`(`uint16` can hold numbers until 2^16-1 = 65535) would not suffice and we would use a variable of the type `uint24`(`uint24` can hold numbers until 2^24-1 = 16777215) allowing us to store every possible postal code.
2. Grouping all data types that are supposed to go together into one 32 byte slot, and declare them one after another in your code. It is important to group data types together as the EVM stores the variables one after another in the given order. This is only done for state variables and inside of structs. Arrays consist of only one data type, so there is no ordering necessary.

It is possible to store as many variables into one storage slot, as long as the combined storage requirement is equal to or less than the size of one storage slot, which is 32 bytes. For example, one `bool` variable takes up one byte. A `uint8` is one byte as well, `uint16` is two bytes, `uint32` four bytes, and so on. The storage requirement of the `bytes` data type is easy to remember, since for example `bytes4` takes exactly four bytes. So theoretically 32 `uint8` variables can be stored in the same space as one `uint256` can. This only works if the variables are declared one after another in the code, because if one bigger data type has to be stored in between, a new slot in storage is used.

如适用性部分所示，此模式可用于状态变量、结构体内部和静态大小的数组。该模式的实现非常直接，可分为两个任务：

1. 使用最小可能的数据类型，以确保代码的正确执行。例如，德国的邮政编码最多有5位数字。因此，数据类型 `uint16`（`uint16`可以容纳数字直到2^16-1 = 65535）不足以满足条件，我们将使用类型为 `uint24`的变量（`uint24`可以容纳数字直到2^24-1 = 16777215），从而允许我们存储每个可能的邮政编码。
2. 将所有应该一起放置的数据类型组合成一个32字节槽，并在您的代码中依次声明它们。重要的是将数据类型分组，因为EVM按照给定顺序将变量存储在一起。这仅适用于状态变量和结构体内部。数组仅由一个数据类型组成，因此不需要排序。

只要组合存储要求等于或小于一个存储槽大小（即32字节），就可以将尽可能多的变量存储到一个存储槽中。例如，一个 `bool`变量占用一个字节。`uint8`也是一个字节，`uint16`是两个字节，`uint32`是四个字节，以此类推。对于 `bytes`数据类型的存储要求很容易记住，因为例如 `bytes4`正好占用四个字节。因此，理论上可以在同一空间中存储32个 `uint8`变量，就像存储一个 `uint256`变量一样。这仅在变量在代码中依次声明的情况下才有效，因为如果必须在中间存储一个更大的数据类型，则会使用存储中的新槽。

## Sample Code

As an example we show how to use the pattern in the context of a struct.

```Solidity
contract StructPackingExample {
  
    struct CheapStruct {
        uint8 a;
        uint8 b;
        uint8 c;
        uint8 d;
        bytes1 e;
        bytes1 f;
        bytes1 g;
        bytes1 h;
    }
  
    CheapStruct example;
  
    function addCheapStruct() public {
        CheapStruct memory someStruct = CheapStruct(1,2,3,4,"a","b","c","d");
        example = someStruct;
    }
}
```

In line 3 we describe a struct object that makes use of the Tight Variable Packing pattern. The eight variables need one byte of storage each and are not interrupted by a bigger type, so they can be packed into one storage slot, where they use 8 of the available 32 bytes. That means we could add more variables into the same storage slot. In line 17 we first initialize a struct object in memory before we write it to storage in line 18.

在第3行，我们描述了一个利用“紧密变量打包”模式的结构体对象。这8个变量每个需要一个字节的存储空间，且没有被更大的数据类型打断，因此它们可以被打包到一个存储槽中，其中它们使用了可用32字节中的8个字节。这意味着我们可以在同一存储槽中添加更多变量。在第17行，我们首先在内存中初始化一个结构体对象，然后在第18行将其写入存储中。

## Gas Analysis

To quantify the potential reduction in required gas, a test has been conducted using the online solidity compiler Remix. The sample code presented above is compared to a solution that stores the exact same input data but does not use the smallest possible data types, and orders the variables in a way that prevents the EVM to use tight packing. So instead of writing all eight variables into one slot, eight slots are used. The code of the experiment can be found on [GitHub](https://github.com/fravoll/solidity-patterns/blob/master/TightVariablePacking/TightVariablePackingGasExample.sol). The results are shown in the following table:

|                          | Tightly Packed Struct | Struct without Tight Packing |
| :----------------------- | --------------------: | ---------------------------: |
| Contract Creation        |                133172 |                       116560 |
| Saving Struct to Storage |                 57821 |                       161636 |

It can be seen that the gas cost of contract creation is approximately 12% cheaper, when not using smaller data types. This can be explained because the EVM usually operates on 32 bytes at a time. It has to use additional operations in order to reduce the size of an element from its original to its reduced size, in our case from `bytes32` to `bytes1`, which costs extra gas. This cost pays off after saving one of our structs to storage. In our example we save 7 storage slots which amounts to saved gas of around 64%. This considerable amount of gas is not only saved once, but every time a new instance of this struct is stored.

为了量化所需gas量的潜在降低，我们使用在线Solidity编译器Remix进行了测试。上面提供的示例代码与一种解决方案进行了比较，该解决方案存储完全相同的输入数据，但不使用最小可能的数据类型，并按一种防止EVM使用紧密打包的变量顺序排列。因此，不是将所有八个变量写入一个存储槽中，而是使用了八个存储槽。该实验的代码可以在[GitHub](https://github.com/fravoll/solidity-patterns/blob/master/TightVariablePacking/TightVariablePackingGasExample.sol)上找到。结果如下表所示：

|                        | 精细打包的结构体 | 没有精细打包的结构体 |
| ---------------------- | ---------------- | -------------------- |
| 合约创建               | 133172           | 116560               |
| 将结构体保存到存储器中 | 57821            | 161636               |

可以看出，当不使用较小的数据类型时，合约创建的gas成本约便宜了12%。这可以解释为EVM通常一次处理32字节。为了将元素的大小从其原始大小减小到其减小后的大小（在我们的情况下从 `bytes32`到 `bytes1`），它必须使用额外的操作，这会消耗额外的gas。在将我们的结构体之一保存到存储器后，这个成本得到了回报。在我们的示例中，我们节省了7个存储槽，节省了大约64%的gas。这些可观的gas不仅一次性节省，而且每次存储这个结构体的新实例时都会节省。

## Consequences

Consequences of the use of the Tight Variable Packing pattern have to be evaluated before implementing it blindly. The big benefit comes from the substantial amount of gas that can potentially be saved over the lifetime of a contract. But it is also possible to achieve the opposite, higher gas requirements, when not implementing it correctly. The positive effect on gas requirements only works for statically-sized storage variables. Function parameters or dynamically-sized arrays do not benefit from it. On the contrary, as seen in the contract creation costs in the Gas Analysis section, it is even more costly for the EVM to reduce the size of a data type compared to leaving it in its initial state. Another issue may arise when reordering variables to optimize storage usage, which is decreased readability. Usually variables are declared in a logical order. Changing this order could make it harder to audit the code and confuse users as well as developers.

在盲目实施之前，必须评估使用精细变量打包模式的影响。巨大的好处来自于可能在合约生命周期内节省的大量gas。但是，如果没有正确实施，也可能导致相反的结果，即更高的gas要求。对gas要求的积极影响仅适用于静态大小的存储变量。函数参数或动态大小的数组不会从中受益。相反，如gas分析部分中所示的合约创建成本，将数据类型的大小减小比保持其初始状态更为昂贵。另一个问题可能出现在重新排序变量以优化存储使用时，即可读性降低。通常变量是按逻辑顺序声明的。更改此顺序可能会使审核代码更加困难，同时也会使用户和开发人员感到困惑。

## Known Uses

Implementation of this pattern is difficult to observe because it is hard to differentiate if variable types and ordering is chosen with storage packing in mind or because of different reasons. Up until writing no contract could be observed that seemed to have implemented this pattern completely deliberate. One noteworthy example is [Roshambo](https://etherscan.io/address/0xad01fab133e6b9a3308a68931f768ec86e1ad281\#code), a   rock-paper-scissors game that stores each game in a struct. Moves as well as tiebreakers are stored in `uint8` variables, which allow for tight packing. But it looks like this design decision was made without tight packing in mind, as it could be further optimized.

Another example can be found in the [Etherization contract](https://etherscan.io/address/0x3f593a15eb60672687c32492b62ed3e10e149ec6\#code), a DApp that provides a civilization like game on the Ethereum blockchain. In this contract every player is stored in a struct. This time no smaller data types are used, even it would be possible without breaking the logic of the game. By doing this, the gas requirement of storing a new player could be reduced significantly.

实施此模式很难观察，因为很难区分变量类型和排序是出于存储打包考虑还是其他原因。直到目前为止，没有观察到任何似乎完全有意实施了此模式的合约。一个值得注意的例子是[Rock-paper-scissors](https://etherscan.io/address/0xad01fab133e6b9a3308a68931f768ec86e1ad281#code)，这是一个石头剪刀布游戏，它将每个游戏存储在一个结构体中。移动和平局决胜者都存储在 `uint8`变量中，这允许进行紧密打包。但是看起来这个设计决策是在不考虑紧密打包的情况下做出的，因为它可以进一步优化。

另一个例子可以在[Etherization合约](https://etherscan.io/address/0x3f593a15eb60672687c32492b62ed3e10e149ec6#code)中找到，这是一款在以太坊区块链上提供类似文明的游戏的DApp。在这个合约中，每个玩家都存储在一个结构体中。这次没有使用更小的数据类型，即使在不破坏游戏逻辑的情况下也是可能的。通过这样做，存储新玩家的gas要求可以显著降低。

[**< Back**](https://fravoll.github.io/solidity-patterns/)
