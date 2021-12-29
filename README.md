# **MultiSig**
    Contract that requires at least two signatures for sending owner level transactions.
#
## Contract methods
1. ### **addTransaction()**
    **Notice:**  
    **[Only for Owner]**  
    Add new transaction for consideration by the owners.

    **Parameters:**
    * **destination** - address of target contract;
    * **data** - hash value for transaction sending that contains of hash of the target function interface (for example: `sendValue(address,uint)`) and parameters (`0x0000..fa1, 512`);
    * **exparationTime** - timestamp (sec) of exparation time of the transaction.

    **Returns:**
    * **transactiondId** - id of new created transaction in the storage. 

2. ### **voteFor()**
    **Notice:**  
    **[Only for Owner]**  
    Vote for sending the transaction 
    If the owner has confirmed the transaction, he can't confirm it again.  
    The transaction will be sent, if number of confirmation is at least two.  

    **Parameters:**
    * **transactionId** - id of existing transaction.

3. ### **voteContra()**
    **Notice:**  
    **[Only for Owner]**  
    Vote against sending the transaction 
    If the owner has rejected the transaction, he can't reject it again.  
    The transaction will be rejected, if number of contra votes is at least two.  

    **Parameters:**
    * **transactionId** - id of existing transaction.

4. ### **repeatTrxExecution()**
    **Notice:**  
    **[Only for Owner]**  
    An owner can repeat execution of transaction if it wasn't sent for some reason. But it still needs to be accepted by at least 2 owners.   

    **Parameters:**
    * **transactionId** - id of existing transaction.


5. ### **changeOwner()**
    **Notice:**  
    **[Only for delegated calling]**  
    Set a new owner instead of the old one.  
    **To change owner you need to add transaction with `addTransaction()` function add confirm it by 2 owners**. The replacement owner can also vote.

    **Parameters:**
    * **oldOwner** - address of the replacement owner;
    * **newOwner** - address of the new owner;

6. ### **isExist()**
    **Notice:**  
    **[Read method]**  
    Returns `true` if the transaction exists.  

    **Parameters:**
    * **transactionId** - id of existing transaction.

7. ### **getTransactionById()**
    **Notice:**  
    **[Read method]**  
    Returns created transaction structure:  
    * `address destination` - address of target contract;
    * `bytes data` - hash value of function interface and parameters;
    * `uint value` - amount of core currency (in case calling the contract function requires some core tokens);
    * `uint createdAt` - timestamp of transaction creation;
    * `address[3] owners` - list of owners at the time of transaction creation;
    * `TrxStatus status` - the transaction is `PENDING, ACCEPTED, CLOSED` or `EXECUTED` (0, 1, 2, 3 respectively).

    **Parameters:**
    * **transactionId** - id of existing transaction.

8. ### **getOwners()**
    **Notice:**  
    **[Read method]**  
    Returns a list of the actual owners.  

9. ### **getVotesById()**
    **Notice:**  
    **[Read method]**  
    Returns an array of owner votes in the structure:
    * address owner - owner address;
    * Vote vote - owner vote. Votes can be `NON, CONFIRMED` or `CANCELED` (0, 1, 2 respectively).

    **Parameters:**
    * **transactionId** - id of existing transaction.

10. ### **getAvailableToVoteTrxCount()**
    **Notice:**  
    **[Read method]**  
    Returns count of opened to vote transactions.

11. ### **getAllTransactions()**
    **Notice:**  
    **[Read method]**  
    Calls `getTransactionById()` for all transaction. See above.

12. ### **transactionsLength()**
    **Notice:**  
    **[Read method]**  
    Returns the number of transactions created over the entire time. 

13. ### **getTrxAndVotesById()**
    **Notice:**  
    **[Read method]**  
    Returns information from `getTransactionById()` and `getVotesById()` functions. See above.

    **Parameters:**
    * **transactionId** - id of existing transaction.

#
## Deployment 
Before deploying you need to load both files to Remix (MultiSig.sol & libs.sol ) and open there only Multisig.sol, and compile it.  

For compilation use required Compiler version: 0.8.0  
and Enable optimisation: Yes  

Contract constructor requries an array of addresses which will become contract owners.  
Example of constructor for deploying:  

    ["0xCA35b7d915458EF540aDe6068dFe2F44E8fa733c", "0xAb8483F64d9C6d1EcF9b849Ae677dD3315835cb2", "0x5B38Da6a701c568545dCfcB03FcB875f56beddC4"]  

Deploy the contract by orange "deploy" button  

!["alt text"](https://sun9-30.userapi.com/impg/pKZvIjWx1kk1jakk7WHI4Qke9oiFFRIt4xB_IQ/HoXL2qOFXoY.jpg?size=947x757&quality=96&sign=90f3261061b7c39f40cbd14d2776c5a2&type=album)