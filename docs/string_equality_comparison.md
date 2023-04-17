# String Equality Comparison

## Intent

Check for the equality of two provided strings in a way that minimizes average gas consumption for a large number of different inputs.

以一种最小化大量不同输入的平均燃气消耗的方式检查两个提供的字符串是否相等。

## Motivation

Comparing strings in other programming languages is a trivial task. Built-in methods or packages can check for the equality of two inputs in one single call, e.g. `String1.equals(String2)` in Java. Solidity does not support any functionality like this at the time of writing. Therefore, we provide a reliable and gas efficient pattern to check if two strings are equal or not.

Several solutions to this problem have been implemented over the last years. One of the first was part of the [StringUtils library](https://github.com/ethereum/dapp-bin/blob/master/library/stringUtils.sol) provided by the Ethereum Foundation, which did a pairwise comparison of each character and returned false as soon as one pair did not match. This solution returns correct results and uses little gas for short strings and cases where the difference in characters occurs early on. However, gas consumption can get very high for strings that are actually equal as well as long pairs, where the difference is not already in the first few characters. This is because the algorithm has to do a lot of comparisons in these cases. Other forces that lead to varying gas requirements are differences in the average length of strings to compare, as well as different probabilities of correctness. Highly variable and unpredictable gas requirements are a problem for smart contracts, as they bear the risk for transactions to run out of gas and lead to unintended behavior. Therefore, a low, stable and predictable gas requirement is desired.

The solution we propose to mitigate the problem of scaling gas requirement is the usage of a hash function for comparison, combined with a check for matching length of the provided strings, to weed out pairs with different lengths from the start.


在其他编程语言中比较字符串是一项微不足道的任务。内置方法或包可以在一次调用中检查两个输入是否相等，例如 Java 中的 `String1.equals(String2)`。在编写本文时，Solidity 并不支持此类功能。因此，我们提供了一种可靠且燃气高效的模式来检查两个字符串是否相等。

在过去的几年中，已经实现了多种解决此问题的方法。其中一种最早的方法是由以太坊基金会提供的 [StringUtils 库](https://github.com/ethereum/dapp-bin/blob/master/library/stringUtils.sol)，该库对每个字符进行一对一比较，并在一对字符不匹配时返回 false。此解决方案对于短字符串和字符差异出现在前几个字符的情况下，可以返回正确的结果并使用很少的燃气。然而，对于实际上相等但具有较长字符对的字符串，燃气消耗可能会非常高，因为在这种情况下，算法必须进行许多比较。导致燃气需求变化的其他因素包括要比较的字符串的平均长度差异以及正确性的不同概率。高度可变且不可预测的燃气需求对于智能合约是一个问题，因为它们会使交易耗尽燃气并导致意外行为。因此，需要低、稳定且可预测的燃气需求。

我们提出的解决方案以缓解燃气需求的问题是使用哈希函数进行比较，并与检查提供的字符串长度是否匹配相结合，以从一开始就排除长度不同的字符串。

## Applicability

Use the String Equality Comparison pattern when

* you want to check two strings for equality.
* most of your strings to compare are longer than two characters.
* you want to minimize the average amount of gas needed for a broad variety of strings.

当您需要检查两个字符串是否相等时，
当您要比较的大部分字符串长度大于两个字符时，
当您希望最小化广泛的字符串所需的平均燃气量时，
请使用字符串相等比较模式。

## Participants & Collaborations

As there are easier methods to compare two strings than on a blockchain, this pattern is intended mainly for internal use in smart contracts as well as in libraries. In both cases there are only two participants, the called function, which implements the pattern and conducts the actual comparison as well as a calling function. The calling function can call from within the same contract or an inheriting one, or from an external contract, in case of usage in a library.

由于比较两个字符串有比区块链上更简单的方法，因此此模式主要用于智能合约和库内部使用。在这两种情况下，仅有两个参与者，一个是实现模式并执行实际比较的被调用函数，另一个是调用函数。调用函数可以从同一个合约或继承的合约内调用，或者在库中使用时可以从外部合约中调用。

## Implementation

The implementation of this pattern can be grouped into two parts:

1. The first step checks if the two provided strings are of the same length. If this is not the case the function can return that the two strings are not equal and the second step is therefore skipped. To compare the length, the strings have to be converted to the `bytes` data type, which provides a built-in length member. This first step is needed to sort out any string pairs with different length and safe the gas for the hash functions in these cases.
2. In the second step, each string is hashed with the built-in cryptographic function `keccak256()` that computes the Keccak-256 hash of its input. The calculated hashes can then be compared and prove, in case of a complete match, that the two inputs are equal to each other.


此模式的实现可以分为两个部分：

1. 第一步检查两个提供的字符串是否具有相同的长度。如果不是，则函数可以返回两个字符串不相等，并跳过第二步。为了比较长度，字符串必须转换为 `bytes` 数据类型，该类型提供了内置的长度成员。这一步骤是为了筛选出长度不同的字符串对，并在这些情况下为哈希函数节省燃气。
2. 在第二步中，每个字符串使用内置的加密函数 `keccak256()` 进行哈希计算，该函数计算其输入的 Keccak-256 哈希。然后可以比较计算出的哈希值，并在完全匹配的情况下证明两个输入相等。

## Sample Code

```Solidity
function hashCompareWithLengthCheck(string a, string b) internal returns (bool) {
    if(bytes(a).length != bytes(b).length) {
        return false;
    } else {
        return keccak256(a) == keccak256(b);
    }
}
```

The function takes two strings as input parameters and returns true if the strings are equal and false otherwise. In line 2 the strings are cast to bytes and their length is compared. In case of different lengths the function terminates and returns false. If the lengths match, the Keccak256 hashes of both parameters are calculated in line 5 and the result of their comparison is returned.


该函数接受两个字符串作为输入参数，并在这两个字符串相等时返回 true，否则返回 false。在第二行中，将字符串转换为 bytes 类型并比较它们的长度。如果长度不同，则函数终止并返回 false。如果长度相同，则在第 5 行中计算两个参数的 Keccak256 哈希，并返回它们比较的结果。

## Gas Analysis

To quantify the potential reduction in required gas, a test has been conducted using the online solidity compiler Remix. Three different functions to check strings for equality have been implemented:

1. Check with the use of hashes
2. Check by comparing each character; including length check
3. Check with the use of hashes; including length check
   To account for different usage environments, a set of different input pairs has been used that covers short, medium and long strings, as well as matches and differences in early and late stages. The experimental code can be found on [GitHub](https://github.com/fravoll/solidity-patterns/blob/master/StringEqualityComparison/StringEqualityComparisonGasExample.sol).

The results of the evaluation are shown in the following table:

| Input A                              | Input B                    | Hash | Character + Length | Hash + Length |
| :----------------------------------- | :------------------------- | ---: | -----------------: | ------------: |
| abcdefghijklmnopqrstuvwxyz           | abcdefghijklmnopqrstuvwxyz | 1225 |               7062 |          1261 |
| abcdefghijklmnopqrstuvwxy**X** | abcdefghijklmnopqrstuvwxyz | 1225 |               7012 |          1261 |
| **X**bcdefghijklmnopqrstuvwxyz | abcdefghijklmnopqrstuvwxyz | 1225 |                912 |          1261 |
| a**X**cdefghijklmnopqrstuvwxyz | abcdefghijklmnopqrstuvwxyz | 1225 |               1156 |          1261 |
| ab**X**defghijklmnopqrstuvwxyz | abcdefghijklmnopqrstuvwxyz | 1225 |               1400 |          1261 |
| abcdefghijkl                         | abcdefghijklmnopqrstuvwxyz | 1225 |                690 |           707 |
| a                                    | a                          | 1225 |                962 |          1261 |
| ab                                   | ab                         | 1225 |               1156 |          1261 |
| abc                                  | abc                        | 1225 |               1450 |          1261 |

The following findings can be derived:

* Checking with the help of hashes (Option 1 & 3) is more gas efficient then comparing characters as soon as more than two characters would have to be compared. This is the case for matching strings with over two characters or pairs where the difference occurs only after the second position.
* In case of different lengths of the strings, methods that compare the strings before making any other tests (Option 2 & 3) are approximately 40% more efficient than options who do not do this check, regardless of the length of the strings.
* The additional gas usage when using a length check with the hash comparison is only around 3%, while it has the potential to save around 40% of gas every time the lengths do not match.
* The required amount of gas for the functions using hashes (Option 1 & 3) is very stable compared to the one comparing characters (Option 2), where the required gas grows linear with every needed iteration.


为了量化所需燃气的潜在减少，使用在线 solidity 编译器 Remix 进行了一项测试。实现了三个不同的函数来检查字符串是否相等：

1. 使用哈希进行检查
2. 通过比较每个字符进行检查，包括长度检查
3. 使用哈希进行检查，包括长度检查

为了考虑不同的使用环境，使用了一组不同的输入对，涵盖了短、中、长字符串，以及在早期和晚期阶段的匹配和不匹配情况。实验代码可以在 [GitHub](https://github.com/fravoll/solidity-patterns/blob/master/StringEqualityComparison/StringEqualityComparisonGasExample.sol) 上找到。

评估结果如下表所示：

| 输入 A                               | 输入 B                     | 哈希 | 字符 + 长度 | 哈希 + 长度 |
| ------------------------------------ | -------------------------- | ---- | ----------- | ----------- |
| abcdefghijklmnopqrstuvwxyz           | abcdefghijklmnopqrstuvwxyz | 1225 | 7062        | 1261        |
| abcdefghijklmnopqrstuvwxy**X** | abcdefghijklmnopqrstuvwxyz | 1225 | 7012        | 1261        |
| **X**bcdefghijklmnopqrstuvwxyz | abcdefghijklmnopqrstuvwxyz | 1225 | 912         | 1261        |
| a**X**cdefghijklmnopqrstuvwxyz | abcdefghijklmnopqrstuvwxyz | 1225 | 1156        | 1261        |
| ab**X**defghijklmnopqrstuvwxyz | abcdefghijklmnopqrstuvwxyz | 1225 | 1400        | 1261        |
| abcdefghijkl                         | abcdefghijklmnopqrstuvwxyz | 1225 | 690         | 707         |
| a                                    | a                          | 1225 | 962         | 1261        |
| ab                                   | ab                         | 1225 | 1156        | 1261        |
| abc                                  | abc                        | 1225 | 1450        | 1261        |

可以得出以下结论：

* 当需要比较的字符数超过两个时，使用哈希进行检查（选项 1 和 3）比字符比较更加燃气高效。对于超过两个字符的匹配字符串或仅在第二个位置后不同的字符串对，情况都是如此。
* 在字符串长度不同的情况下，先进行字符串比较（选项 2 和 3）然后再进行其他测试的方法比不进行此检查的选项效率高约 40%，无论字符串的长度如何。
* 在哈希比较中使用长度检查时，额外的燃气使用量仅约为 3%，而每当长度不匹配时，其潜在节省的燃气量约为 40%。
* 使用哈希的函数（选项 1 和 3）所需的燃气量非常稳定，而与之相比，使用字符比较的函数（选项 2）所需的燃气量随每次迭代的需要而线性增长。

## Consequences

The consequences of our proposed implementation of a string equality check with the use of hashes and a length comparison can be evaluated in regards to correctness and gas requirement. Correctness can be assumed to be ideal, since the chance of two strings having the same hash without being equal is negligible low. Gas consumption is in most cases not optimal. We showed in the Gas Analysis section, that in the case of two very short strings, Option 2 was slightly more efficient, while in the other cases Option 1 was cheaper. But combined, our implementation makes a good trade off between the other options and performs only slightly worse in some cases but significantly better in the others. Thus making it the best option in most of the scenarios when no exact prediction about input parameters can be made. Another benefit is that the required gas is very stable and does not grow linear with the length of the string, as it does in Option 2, making it a scalable even for very long strings.

使用哈希和长度比较实现字符串相等检查的后果可以从正确性和燃气消耗两方面进行评估。正确性可以假定是理想的，因为两个字符串的哈希相同但不相等的概率极低。在大多数情况下，燃气消耗不是最优的。我们在燃气分析部分中展示，对于两个非常短的字符串，选项 2 稍微更有效率，而在其他情况下，选项 1 更便宜。但是，综合考虑，我们的实现在其他选项中进行了很好的折衷，有时表现略差，但在其他情况下表现显著更好。因此，在不能对输入参数进行精确预测的大多数情况下，这是最好的选择。另一个好处是所需的燃气非常稳定，并且不像选项 2 那样随字符串长度线性增长，使其可扩展性更好，即使对于非常长的字符串也是如此。

## Known Uses

Usage of this pattern in a production environment could not be observed up until the point of writing.

[**< Back**](https://fravoll.github.io/solidity-patterns/)
