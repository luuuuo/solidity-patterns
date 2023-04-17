// This code has not been professionally audited, therefore I cannot make any promises about
// safety or correctness. Use at own risk.

pragma solidity ^0.4.20;

contract GuardCheck {

    function donate(address addr) payable public {
        require(addr != address(0));
        require(msg.value != 0);
        uint balanceBeforeTransfer = this.balance;
        uint transferAmount;

        if (addr.balance == 0) {
            transferAmount = msg.value;
        } else if (addr.balance < msg.sender.balance) {
            transferAmount = msg.value / 2;
        } else {
            revert();
        }

        addr.transfer(transferAmount);
        assert(this.balance == balanceBeforeTransfer - transferAmount);
    }
}

struct ExpensiveStruct {
    uint64 a; //uses 8 bytes
    bytes32 e; //uses 32 bytes writes in new slot
    uint64 b; //uses 8 bytes writes in new slot
    bytes32 f; //uses 32 bytes writes in new slot
    uint32 c; //uses 4 bytes writes in new slot
    bytes32 g; //uses 32 bytes writes in new slot
    uint8 d; //uses 1 byte writes in new slot
    bytes32 h; //uses 32 bytes writes in new slot
}

struct ExpensiveStruct {
    uint64 a;
    uint32 c;
    uint64 b;
    uint8 d;
    bytes32 e;
    bytes32 f;
    bytes32 g;
    bytes32 h;
}