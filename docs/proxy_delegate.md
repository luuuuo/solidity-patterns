# Proxy Delegate

## Intent

Introduce the possibility to upgrade smart contracts without breaking any dependencies.

## Motivation

Mutability in Ethereum is hard to achieve, but necessary. It allows developers to adapt to a changing environment and to react to bugs and other errors. To overcome the limitations introduced by the immutability of contract code, a contract can be split up into modules, which are then virtually upgradeable. They are only virtually upgradeable, because existing contracts still cannot be changed. However, a new version of the contract can be deployed and its address replaces the old one in storage. To avoid breaking dependencies of other contracts that are referencing the upgraded contract, or users who do not know about the release of a new contract version (that comes with a new address), we make use of a proxy (sometimes also called dispatcher) contract that delegates calls to the specific modules. These modules are also called delegates, as work is delegated to them by the proxy. A first functional version of this pattern was introduced in [2016](https://www.reddit.com/r/ethereum/comments/4kt1zp/mad_blockchain_science_a_100_upgradeable_contract/).

This example makes use of a special message call, named `delegatecall`. Using this new message call allows a contract to pass on the function call to the delegate without having to explicitly know the function signature, a crucial point for upgradeability. Another difference to a regular message call is, that with a `delegatecall` the code at the target address is executed in the context of the calling contract. This means that the storage and state of the calling contract are used. Additionally, transaction properties like `msg.sender` and `msg.value` will remain the ones of the initial caller.

This pattern often goes hand in hand with the [Eternal Storage pattern](./eternal_storage.md) to further decouple storage from contract logic.


在以太坊中，可变性很难实现，但是是必要的。它允许开发人员适应不断变化的环境，并对错误和其他问题做出反应。为了克服合约代码不可变性引入的限制，合约可以分成模块，然后虚拟升级。它们仅在虚拟上是可升级的，因为现有的合约仍然无法更改。然而，可以部署合约的新版本，并将其地址替换存储中的旧版本。为避免破坏引用升级合约的其他合约的依赖关系或不知道新合约版本（带有新地址）发布的用户，我们利用代理（有时也称为调度器）合约，将调用委托到特定模块。这些模块也称为代理，因为代理将工作委托给它们。这种模式的第一个功能版本在[2016年](https://www.reddit.com/r/ethereum/comments/4kt1zp/mad_blockchain_science_a_100_upgradeable_contract/)被引入。

这个例子使用了一种特殊的消息调用，称为 `delegatecall`。使用这个新的消息调用允许合约将函数调用传递给委托，而无需明确知道函数签名，这是可升级性的一个关键点。与常规消息调用的另一个区别是，使用 `delegatecall`时，目标地址的代码在调用合约的上下文中执行。这意味着使用调用合约的存储和状态。此外，事务属性，如 `msg.sender`和 `msg.value`，将保留最初调用方的属性。

这种模式通常与永久存储模式结合使用，以进一步将存储与合约逻辑解耦。

## Applicability

Use the Proxy Delegate pattern when

* you want to delegate function calls to other contracts.
* you need upgradeable delegates, without breaking dependencies.
* you are familiar with advanced concepts like delegatecalls and inline assembly.

当您需要将函数调用委托给其他合约、需要可升级的代理而不破坏依赖关系、熟悉委托调用和内联汇编等高级概念时，可以使用代理委托模式。

## Participants & Collaborations

There are several participants interacting with each other in this pattern. The basic idea is that a caller (external or contract address) makes a function call to the proxy, which delegates the call to the delegate, where the function code is located. The result is then returned to the proxy, which forwards it to the caller. To know at which address the current version of the delegate resides, the proxy can either store it itself in a variable, or in case the [Eternal Storage pattern](./eternal_storage.md) is used, consult the external storage for the current address.

Because `delegatecall` is used to delegate the call, the called function is executed in the context of the proxy. This further means that the storage of the proxy is used for function execution, which results in the limitation that the storage of the delegate contract has to be append only. What this means is, that in case of an upgrade, existing storage variables cannot be omitted or changed, only new variables are allowed to be added. This is because changing the storage structure in the delegate would mess up storage in the proxy, which is expecting the previous structure. An example for this behavior can be found in the [GitHub repository](https://github.com/fravoll/solidity-patterns/blob/master/ProxyDelegate/StorageOverwriteExample.sol).


在这种模式中，有几个参与者相互交互。基本思想是，调用者（外部或合约地址）向代理发出函数调用，代理将调用委托给代理，在那里函数代码被定位。然后将结果返回给代理，代理将其转发给调用者。为了知道委托的当前版本位于哪个地址，代理可以将其存储在变量中，或者如果使用了永久存储模式，则查询外部存储以获取当前地址。

因为使用了 `delegatecall`来委托调用，所以被调用的函数在代理的上下文中执行。这进一步意味着代理的存储用于函数执行，这导致了委托合约的存储必须仅追加的限制。这意味着，在升级时，现有的存储变量不能被省略或更改，只允许添加新变量。这是因为在代理中更改委托中的存储结构会破坏代理中的存储，而代理期望先前的结构。这种行为的示例可以在[GitHub存储库](https://github.com/fravoll/solidity-patterns/blob/master/ProxyDelegate/StorageOverwriteExample.sol)中找到。


## Implementation

The implementation of the Proxy part of the pattern is more complex than most of the other patterns presented in this document. A `delegatecall` is used to execute functions at a delegate in the context of the proxy and without having to know the function identifiers, because `delegatecall` forwards the `msg.data`, containing the function identifier in the first four bytes. In order to trigger the forwarding mechanism for every function call, it is placed in the proxy contract's fallback function. Unfortunately a `delegatecall` only returns a boolean variable, signaling the execution outcome. When using the call in the context of a proxy, however, we are interested in the actual return value of the function call. To overcome this limitation, inline assembly (inline assembly allows for more precise control over the stack machine, with a language similar to the one used by the EVM and can be used within solidity code) has to be used. With the help of inline assembly we are able to dissect the return value of the `delegatecall` and return the actual result to the caller. Due to the complexity of inline assembly, any further explanation on the implemented functionality, will be done with the help of an example in the Sample Code section of this pattern. One way of circumventing the need for inline assembly would be returning the result to the caller via events. While events cannot be accessed from within a contract, it would be possible to listen to them from the front end and act according to the result from there on. This method, however, will not be discussed in this pattern.

As stated in the Participants & Collaborations section, the upgrading mechanism, hence, storing of the current version of the delegate, can either happen in external storage or in the proxy itself. In case the address is stored in the proxy, a guarded function has to be implemented, which lets an authorized address update the delegate address.

The delegate can be implemented in the same way as any regular contract and no special precautions have to be taken, as the delegate does not have to know about the proxy using its code. The only thing that has to be taken into account is, that while upgrading the contract, storage sequence has to be the same; only additions are permitted.

在这个模式中，代理部分的实现比本文介绍的其他模式更为复杂。使用 `delegatecall`在代理的上下文中执行委托的函数，无需知道函数标识符，因为 `delegatecall`转发包含函数标识符在前四个字节的 `msg.data`。为了触发每个函数调用的转发机制，它被放置在代理合约的回退函数中。不幸的是，`delegatecall`只返回一个布尔变量，表示执行结果。然而，在代理的上下文中使用调用时，我们对函数调用的实际返回值感兴趣。为了克服这一限制，必须使用内联汇编（内联汇编允许更精细地控制堆栈机器，使用类似于EVM的语言，并可以在Solidity代码中使用）。借助内联汇编，我们能够分解 `delegatecall`的返回值，并将实际结果返回给调用者。由于内联汇编的复杂性，任何有关实现功能的进一步解释都将在此模式的示例代码部分中进行。避免使用内联汇编的一种方法是通过事件将结果返回给调用者。虽然事件无法从合约内部访问，但可以从前端监听它们，并根据结果进行操作。但是，本模式不会讨论这种方法。

如“参与者和合作”一节所述，升级机制和代理的当前版本存储可以在外部存储中或代理自身中发生。如果地址存储在代理中，则必须实现一个受保护的函数，让授权的地址更新委托地址。

委托可以像任何常规合约一样实现，并且不需要采取特殊预防措施，因为委托不需要知道代理使用其代码。唯一需要考虑的是，在升级合约时，存储顺序必须相同；只允许添加。

## Sample Code

This generic example of a Proxy contract is inspired by [this post](https://medium.com/@daonomic/upgradeable-ethereum-smart-contracts-d036cb373d6) and stores the current version of the delegate in its own storage. Because the design of the Delegate contract can take many forms, there is no explicit example given.

```Solidity
contract Proxy {

    address delegate;
    address owner = msg.sender;

    function upgradeDelegate(address newDelegateAddress) public {
        require(msg.sender == owner);
        delegate = newDelegateAddress;
    }

    function() external payable {
        assembly {
            let _target := sload(0)
            calldatacopy(0x0, 0x0, calldatasize)
            let result := delegatecall(gas, _target, 0x0, calldatasize, 0x0, 0)
            returndatacopy(0x0, 0x0, returndatasize)
            switch result case 0 {revert(0, 0)} default {return (0, returndatasize)}
        }
    }
}
```

The address variables in line 3 and 4 store the address of the delegate and the owner, respectively. The `upgradeDelegate(..)` function is the mechanism that allows a new version of the delegate being used, without the caller of the proxy having to worry about it. An authorized entity, in this case the owner (checked with a simple form of the [Access Restriction pattern](./access_restriction.md) in line 7) is able to provide the address of a new delegate version, which replaces the old one (line 8).

The actual forwarding functionality is implemented in the function starting from line 11. The function does not have a name and is therefore the fallback function, which is being called for every unknown function identifier. Therefore, every function call to the proxy (besides the ones to `upgradeDelegate(..)`) will trigger the fallback function and execute the following inline assembly code:
Line 13 loads the first variable in storage, in this case the address of the delegate, and stores it in the memory variable `_target`. Line 14 copies the function signature and any parameters into memory. In line 15 the `delegatecall` to the `_target` address is made, including the function data that has been stored in memory. A boolean containing the execution outcome is returned and stored in the `result` variable. Line 16 copies the actual return value into memory. The switch in line 17 checks whether the execution outcome was negative, in which case any state changes are reverted, or positive, in which case the result is returned to the caller of the proxy.


这是一个代理合约的通用示例，灵感来自于这篇文章，并将委托合约的当前版本存储在自己的存储器中。由于委托合约的设计可以采用多种形式，因此没有提供明确的示例。

第3行和第4行的地址变量分别存储委托和所有者的地址。`upgradeDelegate(..)`函数是允许使用新版本的委托的机制，而不必担心代理的调用者。授权实体（在本例中是所有者，在第7行使用简单形式的访问限制模式进行检查）能够提供新委托版本的地址，该地址将取代旧版本的委托（第8行）。

从第11行开始实现了实际的转发功能。该函数没有名称，因此是后备函数，对于每个未知的函数标识符都会调用它。因此，对于代理的每个函数调用（除了 `upgradeDelegate(..)`之外），都将触发后备函数并执行以下内联汇编代码：
第13行加载存储器中的第一个变量，即委托的地址，并将其存储在内存变量 `_target`中。第14行将函数签名和任何参数复制到内存中。第15行执行 `delegatecall`，调用 `_target`地址，包括存储在内存中的函数数据。返回一个包含执行结果的布尔值，并将其存储在变量 `result`中。第16行将实际的返回值复制到内存中。第17行的 `switch`语句检查执行结果是否为负，如果是，则撤消任何状态更改，如果为正，则将结果返回给代理的调用者。

## Consequences

There are several implications that should be considered when using the Proxy Delegate pattern for achieving upgradeability. With its implementation, complexity is increased drastically and especially developers new to smart contract development with Solidity, might find it difficult to understand the concepts of delegatecalls and inline assembly. This increases the chance of introducing bugs or other unintended behavior. Another point are the limitations on storage changes: fields cannot be deleted nor rearranged. While this is not an insurmountable problem, it is important to be aware of, in order to not accidentally break contract storage. An important negative consequence from a social perspecive is the potential loss in trust from users. With upgradeable contracts, immutability as one of the key benefits of blockchains, can be avoided. Users have to trust the responsible entities to not introduce any unwanted functionality with one of their upgrades. A solution to this caveat could be strategies that only allow for partial upgrades. Core features could be non-upgradeable, while other, less essential, features are implemented with the option for upgrades. If this approach is not applicable, a trust loss could also be mitigated by introducing a test period, during which upgrades can be carried out. After the expiration of the test period, the contract cannot be changed any longer.

Besides these negative consequences, the Proxy Delegate pattern is an efficient way to separate the upgrading mechanism from contract design. It allows for upgradeability, without breaking any dependencies.


使用代理委托模式实现可升级性时，需要考虑几个重要的方面。其实现会显著增加复杂性，特别是对于刚接触Solidity智能合约开发的开发人员来说，可能难以理解delegatecalls和内联汇编的概念，从而增加引入错误或其他意外行为的风险。另一个问题是关于存储更改的限制：字段无法删除或重新排列。虽然这不是一个无法克服的问题，但必须意识到这一点，以免意外破坏合约存储。从社会角度看，一个重要的负面后果是可能会导致用户对信任的损失。使用可升级合约，块链的不变性作为其关键好处之一，可能会被避免。用户必须信任负责的实体不会在升级中引入任何不需要的功能。解决这一问题的方法可能是只允许进行部分升级的策略。核心功能可以是不可升级的，而其他较不重要的功能可以实现为可升级的。如果这种方法不适用，那么可以通过引入测试期来缓解信任损失。在测试期结束后，合约将无法再进行更改。

除了这些负面后果外，代理委托模式是一种有效的方法，可以将升级机制与合约设计分离。它允许实现可升级性，而不会破坏任何依赖关系。

## Known Uses

Implementations of the Proxy Delegate pattern are more likely to be found in bigger DApps, containing a large number of contracts. One example for this is [Augur](https://github.com/AugurProject/augur-core/blob/master/source/contracts/libraries/Delegator.sol), a prediction market that lets users bet on the outcome of future events. In this case the address of the upgradeable contract is not stored in the proxy itself, but in some kind of address resolver.

[**< Back**](https://fravoll.github.io/solidity-patterns/)
