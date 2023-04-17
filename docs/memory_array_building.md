# Memory Array Building

## Intent

Aggregate and retrieve data from contract storage in a gas efficient way.

以一种高效的方式从合约存储中聚合和检索数据。其中，"gas efficient"表示需要尽可能地减少操作合约所需的gas成本。

## Motivation

Interacting with the storage of a contract on the blockchain is among the most expensive operations of the EVM. Therefore, only necessary data should be stored and redundancy should be avoided if possible. This is in contrast to conventional software architecture, where storage is cheap and data is stored in a way that optimizes performance. While most of the times the only relevant cost of queries in those systems is time, in Ethereum even simple queries can cost a substantial amount of gas, which has a direct monetary value. One way to mitigate gas costs is declaring a variable public. This leads to the creation of a getter in the background allowing free access to the value of the variable. But what if we want to aggregate data from several sources? This would require a lot of reading from storage and would therefore be particularly costly.

By using this pattern we are making use of the `view` function modifier in Solidity, which allows us to aggregate and read data from contract storage without any associated costs. Everytime a lookup is requested, an array is rebuilt in memory, instead of saving it to storage. This would be inefficient in conventional systems. In Solidity the proposed solution is more efficient because functions declared with the `view` modifier are not allowed to write to storage and therefore do not modify the state of the blockchain (the [Solidity documentation](http://solidity.readthedocs.io/en/v0.4.21/index.html) gives an overview over what is considered modifying the state). All data necessary for the execution of these functions can be fetched from the local node. Since the blockchain state stays the same, there is no need to broadcast a transaction to the network. No transaction means no consumed gas, making the call of a view function free, as long as it is called externally and not from another contract. In that case, a transaction would be necessary and gas would be consumed.

与区块链上合约存储进行交互是EVM中最昂贵的操作之一。因此，只有必要的数据应该被存储，如果可能的话应该避免冗余。这与传统的软件架构相反，传统架构中存储是便宜的，并且数据以优化性能的方式存储。在大多数情况下，这些系统中查询的唯一相关成本是时间，而在以太坊中，即使是简单的查询也可能会消耗大量的gas，这直接影响到经济成本。减少gas成本的一种方法是声明一个变量为public。这会创建一个getter函数，使得可以免费访问变量的值。但是，如果我们想要从多个来源聚合数据呢？这将需要大量的存储读取，因此成本特别高昂。

通过使用这种模式，我们可以利用Solidity中的 `view`函数修饰符，以无需任何相关成本的方式从合约存储中聚合和读取数据。每次请求查找时，都会在内存中重新构建一个数组，而不是将其保存到存储中。在传统系统中，这将是低效的。在Solidity中，所提出的解决方案更加高效，因为使用 `view`修饰符声明的函数不允许写入存储，因此不会修改区块链的状态（[Solidity文档](http://solidity.readthedocs.io/en/v0.4.21/index.html)概述了什么被认为是修改状态）。这些函数执行所需的所有数据都可以从本地节点获取。由于区块链状态保持不变，因此无需向网络广播交易。没有交易就没有消耗的gas，使得调用视图函数是免费的，只要它是从外部调用的，而不是从另一个合约调用的。在那种情况下，将需要一笔交易，并且会消耗gas。

## Applicability

Use the Memory Array Building pattern when

* you want to retrieve aggregated data from storage.
* you want to avoid paying gas when retrieving data.
* your data has attributes that are subject to changes.

当满足以下条件时，可以使用内存数组构建模式：

* 您希望从存储中检索聚合数据。
* 您希望在检索数据时避免支付gas。
* 您的数据具有可能会更改的属性。

## Participants & Collaborations

Participants in this pattern are the implementing contract itself as well as an entity requesting the stored data. To achieve a completely free request, the request has to be made externally, meaning not from another contract inside the network, as this would lead to the need for a gas intensive transaction.

这种模式中的参与者包括实现合约本身以及请求存储数据的实体。为了实现完全免费的请求，请求必须是外部的，也就是不是来自网络中的另一个合约，因为这将导致需要进行高昂的gas交易。

## Implementation

The implementation of this pattern can be divided into two parts. Part one covers the way the requested data is stored, whereas part two explains the actual aggregation and retrieval of the data:

1. To make data retrieval convenient it makes sense to chose a data structure that is easy to iterate over. In Solidity this is achieved by an array. In cases where aggregation is necessary, the data usually has more than one attribute. This characteristic can be implemented by a custom data type in the form of a struct. Combining these requirements, we end up with an array of structs, with the struct containing all attributes of an item. Another indispensable part is a mapping, which keeps track of the number of expected data entries for every possible aggregation instance. This mapping will come into play in part two.
2. The aggregation is then performed in a view function, so that no gas is consumed. A problem that makes the task a little more difficult is the fact that Solidity does not allow an array of structs as a return value of a function [yet](https://github.com/ethereum/solidity/issues/2948). We therefore propose a workaround that only returns the IDs of the desired items. It is then the task of the requesting entity to use these IDs to query the structs one by one. As the state is not changed by these additional operations, the queries are free as well. To gather the IDs of the desired items we first create an array to store them. Since we are not allowed to change the contract state in a view function we will create this array in memory. In Solidity it is not possible to create dynamic arrays in memory, so we can now make use of the mapping containing the number of expected entries from part one, and use it as the length for our array. The actual aggregation is done via a for-loop over all stored items. The IDs of all items that fit into the aggregation schema are saved into the memory array and returned after all items have been checked. Since all this computation is performed on the local node and not by every node on the network it is no problem to do such an otherwise expensive iteration over a dynamical array, since we can not run out of gas.

该模式的实现可以分为两个部分。第一部分涵盖了所请求数据的存储方式，而第二部分则解释了实际的数据聚合和检索：

1. 为了方便数据检索，选择一种易于迭代的数据结构是有道理的。在Solidity中，可以通过数组实现这一点。在需要进行聚合的情况下，数据通常具有多个属性。可以通过自定义数据类型（struct）来实现这种特性。将这些要求结合起来，我们最终得到了一个包含所有项属性的结构体数组，其中每个结构体表示一个项。另一个必不可少的部分是一个映射（mapping），用于跟踪每个可能的聚合实例的预期数据条目数。这个映射将在第二部分发挥作用。
2. 然后，聚合是在视图函数中执行的，因此不会消耗gas。使任务有点困难的问题是，Solidity不允许将结构体数组作为函数的返回值[（目前）](https://github.com/ethereum/solidity/issues/2948)。因此，我们提出了一个解决方法，只返回所需项的ID。然后，请求实体的任务是使用这些ID逐个查询结构体。由于这些额外操作不会改变状态，因此这些查询也是免费的。为了收集所需项的ID，我们首先创建一个数组来存储它们。由于不能在视图函数中更改合约状态，所以我们将在内存中创建此数组。在Solidity中，不可能在内存中创建动态数组，因此我们可以利用第一部分中包含的预期条目数映射，并将其用作数组的长度。实际的聚合是通过一个for循环来遍历所有存储的项完成的。符合聚合模式的所有项的ID都将保存在内存数组中，并在检查完所有项后返回。由于所有这些计算都在本地节点上执行，而不是由网络上的每个节点执行，因此在动态数组上进行这样一个本来昂贵的迭代是没有问题的，因为我们不会耗尽gas。

## Sample Code

In this sample we show how a collection of items can be aggregated over its owners.

```Solidity
contract MemoryArrayBuilding {

    struct Item {
        string name;
        string category;
        address owner;
        uint32 zipcode;
        uint32 price;
    }

    Item[] public items;

    mapping(address => uint) public ownerItemCount;

    function getItemIDsByOwner(address _owner) public view returns (uint[]) {
        uint[] memory result = new uint[](ownerItemCount[_owner]);
        uint counter = 0;
  
        for (uint i = 0; i < items.length; i++) {
            if (items[i].owner == _owner) {
                result[counter] = i;
                counter++;
            }
        }
        return result;
    }
}
```

In line 3 an example struct is defined containing several attributes, including the owner over which we will aggregate later on. The array in line 11 contains all existing instances of items. In line 13 we store the amount of items every address holds, which is necessary to initialize the memory array in line 16. The function to retrieve all IDs of items belonging to a certain address in line 15 contains the `view` modifier. In the for-loop starting in line 19 we iterate over all items and check if their owner corresponds to the one we are aggregating over (line 20). If the owners match, we store the ID in our array. After all items have been checked the array is returned. It is now possible for the requesting entity to query the items by their respective IDs without the need for a transaction, since the `items` array in line 11 is public.

在第3行中，定义了一个示例结构体，其中包含几个属性，包括以后将进行聚合的所有者。第11行的数组包含所有现有的物品实例。在第13行中，我们存储每个地址持有的物品数量，这是初始化第16行中的内存数组所必需的。在第15行中，用于检索属于某个地址的所有物品ID的函数包含了 `view`修饰符。在从第19行开始的for循环中，我们遍历所有物品，并检查它们的所有者是否与我们要聚合的所有者相对应（第20行）。如果所有者匹配，我们就将ID存储在数组中。在检查完所有物品之后，返回该数组。现在，请求实体可以通过它们各自的ID查询物品，而无需进行交易，因为第11行的 `items`数组是公开的。

## Gas Analysis

The analysis of gas consumption in this pattern is fairly easy. Again the Solidity online compiler Remix is used to compute the required gas. The code of the experiment can be found on [GitHub](https://github.com/fravoll/solidity-patterns/blob/master/MemoryArrayBuilding/MemoryArrayBuildingGasExample.sol). In our experiment we use the setting presented in the Sample Code section and initialize it with ten items of which two belong to the examined address. We then call the `getItemIDsByOwner(address _owner)` function twice from an external account as well as from another contract. One of the two times the function contains the `view` modifier and one time it does not. The results can be found in the following table and show how only a combination from an external call and the view function leads to a free query, while the other combinations cost gas like a regular function call would, because an actual transaction is broadcasted to the network.

在这个模式中，对gas消耗的分析相当容易。同样，使用 Solidity 在线编译器 Remix 计算所需的gas。实验代码可以在 [GitHub](https://github.com/fravoll/solidity-patterns/blob/master/MemoryArrayBuilding/MemoryArrayBuildingGasExample.sol) 上找到。在我们的实验中，我们使用示例代码部分中提供的设置，并用其中两个物品属于被检查的地址的十个物品进行了初始化。然后，我们从外部账户和另一个合约中两次调用 `getItemIDsByOwner(address _owner)`函数。其中一次函数包含 `view`修饰符，另一次则没有。结果如下表所示，只有外部调用和视图函数的组合会导致免费查询，而其他组合会像普通函数调用一样产生gas费用，因为实际的交易会广播到网络中。

|          | 视图函数 | 普通函数 |
| -------- | -------- | -------- |
| 外部调用 | 0        | 32623    |
| 内部调用 | 32623    | 32623    |

|               | View Function | Regular Function |
| :------------ | ------------: | ---------------: |
| External Call |             0 |            32623 |
| Internal Call |         32623 |            32623 |

## Consequences

The most obvious consequence of applying the Memory Array Building pattern is the complete circumvention of transaction costs, a benefit that can save a substantial amount of money in case the function is used frequently. An alternative to the proposed way would be to store one array for every instance we would want to aggregate over (e.g. for every owner). This would lead to significant gas requirements as soon as we wanted to change the owner of one item. We would have to remove the item from one array, add it to another array, shift every element in the first array to fill the empty space as well as reducing the length of the array. All of this are expensive operations on contract storage. To change an attribute in the proposed solution, only the actual attribute and the mapping that keeps track of the length would have to be changed.

But the pattern does not only come with benefits. By implementing it, we increase complexity. It is unintuitive to store all items in one array compared to having separate arrays. Also the concept of doing aggregation on every single call instead of aggregating once and storing it that way might be confusing in the beginning.

应用内存数组构建模式的最明显的结果是完全绕过交易费用，这一优点可以在函数频繁使用时节省大量资金。提出的替代方案是为我们想要聚合的每个实例存储一个数组（例如每个所有者）。一旦我们想要更改一个物品的所有者，这将导致显著的gas要求。我们必须从一个数组中删除该物品，将其添加到另一个数组中，将第一个数组中的每个元素移动以填充空白空间，并缩短数组的长度。所有这些都是合约存储上昂贵的操作。在所提出的解决方案中更改属性时，只需要更改实际属性和跟踪长度的映射即可。

但是，该模式不仅带来了好处。通过实现它，我们增加了复杂性。与使用单独的数组相比，将所有物品存储在一个数组中是不直观的。此外，在每次调用上进行聚合而不是一次聚合并以这种方式存储的概念可能在一开始会令人困惑。

## Known Uses

An implementation of this pattern can be found in the infamous [CryptoKitties contract](https://etherscan.io/address/0x06012c8cf97bead5deae237070f9587f8e7a266d\#code). In line 651 we find a function called `\lstinline|tokensOfOwner(address _owner)` which returns the IDs of all Kitties that belong to a given address.

Another example is the now closed, Ethereum based slot machine [Slotthereum](https://etherscan.io/address/0xda8fe472e1beae12973fa48e9a1d9595f752fce0\#code). In this contract, the pattern was used in a similar fashion as in our example, to retrieve the IDs of all games.

可以在臭名昭著的 [CryptoKitties 合约](https://etherscan.io/address/0x06012c8cf97bead5deae237070f9587f8e7a266d#code)中找到此模式的实现。在第 651 行，我们找到了一个名为 `\lstinline|tokensOfOwner(address _owner)` 的函数，它返回属于给定地址的所有 Kitties 的 ID。

另一个例子是现在关闭的基于以太坊的老虎机游戏 [Slotthereum](https://etherscan.io/address/0xda8fe472e1beae12973fa48e9a1d9595f752fce0#code)。在这个合约中，该模式被用于类似于我们的示例中的方式，以检索所有游戏的 ID。

[**< Back**](https://fravoll.github.io/solidity-patterns/)
