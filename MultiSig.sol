// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.0;

import "./libs.sol";


contract MultiSig{
    using SafeMath for uint;
    mapping(address => bool) public isOwner;
    // transaction_id => ownerAddress => Vote 
    mapping(uint => mapping(address => Vote)) public votes;
    Transaction[] transactions;
    
    address[3] private _owners;
    
    enum Vote {NON, VOTED_FOR, VOTED_CONTRA}
    enum TrxStatus {PENDING, ACCEPTED_FAILED, REJECTED, ACCEPTED_EXECUTED}

    struct Transaction {
        address destination;
        bytes data;
        uint value;
        uint createdAt;
        address[3] owners;
        TrxStatus status;
        uint256 exparationTime;
    }
    
    struct OwnerVote {
        address owner;
        Vote vote;
    }
    
    constructor(address[3] memory owners){
        for (uint i = 0; i < owners.length; i++){
            require(owners[i] != address(0) && !isOwner[owners[i]]);
            isOwner[owners[i]] = true;
        }
        _owners = owners;
    }
    
    modifier onlyOwner() {require(isOwner[msg.sender], "Only Owner");_;}
    modifier onlyWallet() {require(msg.sender == address(this), "Only Wallet");_;}
    modifier exist(uint transactionId) {
        require(isExist(transactionId), "Transaction doesn't exist");
        _;
    }
    modifier available(uint transactionId) {
        require(transactions[transactionId].exparationTime >= block.timestamp, "The voting is expired");
        require(transactions[transactionId].status != TrxStatus.REJECTED, "Transaction should be not rejected");
        require(transactions[transactionId].status != TrxStatus.ACCEPTED_EXECUTED, "Transaction should be not executed");
        _;
    }
    
    event Execution(uint transactionId, bytes result);
    event ExecutionFailure(uint transactionId, bytes result);
    event TransactionCreated(uint256 transactionId);
    event VotedFor(uint256 transactionId, address indexed owner);
    event TransactionAccepted(uint256 transactionId, OwnerVote[3] votes);
    event VotedContra(uint256 transactionId, address indexed owner);
    event TransactionClosed(uint256 transactionId, OwnerVote[3] votes);
    
    function addTransaction(address destination, bytes memory data, uint256 exparationTime) public payable onlyOwner returns(uint256 transactionId){
        require(data.length != 0, "Zero data");
        require(destination != address(0), "Zero address");
        Transaction memory trx;
        trx.destination = destination;
        trx.data = data;
        trx.value = msg.value;
        trx.createdAt = block.timestamp;
        trx.owners = _owners;
        trx.status = TrxStatus.PENDING;
        trx.exparationTime = exparationTime;
        transactions.push(trx);
        voteFor(transactionsLength()-1);
        emit TransactionCreated(transactionId);
    }
    
    function voteFor(uint256 transactionId) public exist(transactionId) available(transactionId) onlyOwner{
        require(!isVotedByAddress(transactionId, msg.sender, Vote.VOTED_FOR), "Transaction already confirmed by this address");
        votes[transactionId][msg.sender] = Vote.VOTED_FOR;
        _executeTransaction(transactionId);
        updateStatus(transactionId);
        emit VotedFor(transactionId, msg.sender);
    }

    function voteContra(uint256 transactionId) public exist(transactionId) available(transactionId) onlyOwner {
        require(!isVotedByAddress(transactionId, msg.sender, Vote.VOTED_CONTRA), "Transaction already rejected by this address");
        votes[transactionId][msg.sender] = Vote.VOTED_CONTRA;
        _closeTransaction(transactionId);
        updateStatus(transactionId);
        emit VotedContra(transactionId, msg.sender);
    }

    function updateStatus(uint256 transactionId) private exist(transactionId) {
        if (transactions[transactionId].status == TrxStatus.REJECTED || transactions[transactionId].status == TrxStatus.ACCEPTED_EXECUTED)
            return;
        if (isConfirmed(transactionId)){
            transactions[transactionId].status = TrxStatus.ACCEPTED_FAILED;
            emit TransactionAccepted(transactionId, getVotesById(transactionId));
        }
        else
            transactions[transactionId].status = TrxStatus.PENDING;
    } 
    
    function isConfirmed(uint transactionId) private view returns(bool){
        uint confirmationCount = 0;
        for (uint i = 0; i < _owners.length; i++){
            require(isOwner[_owners[i]], "Some address is not owner");
            if (isVotedByAddress(transactionId, _owners[i], Vote.VOTED_FOR))
                confirmationCount = confirmationCount.add(1);
        }
        
        if (confirmationCount >= 2)
            return true;
        return false;
    }
    
    function isVotedByAddress(uint transactionId, address addr, Vote vote) private view returns(bool){
        return votes[transactionId][addr] == vote;
    }
    
    function isExist(uint transactionId) public view returns(bool){
        if (transactionId >= transactions.length)
            return false;
        if (transactions[transactionId].destination != address(0) && 
            transactions[transactionId].data.length != 0 && 
            transactions[transactionId].createdAt != 0)
            return true;
        return false;
    }
    
    function _executeTransaction(uint transactionId) internal exist(transactionId) available(transactionId) onlyOwner{
        if (!isConfirmed(transactionId))
            return;
        Transaction storage txn = transactions[transactionId];
        require(txn.data.length != 0, "Zero data");
        require(txn.destination != address(0), "Zero address");
        (bool success, bytes memory result) = external_call(txn.destination, txn.data, txn.value);
        if (success){
            emit Execution(transactionId, result);
            txn.status = TrxStatus.ACCEPTED_EXECUTED;
        }
        else {
            emit ExecutionFailure(transactionId, result);
        }
    }

    function _closeTransaction(uint transactionId) internal exist(transactionId) available(transactionId) onlyOwner {
        uint cancelCount = 0;
        for (uint i = 0; i < _owners.length; i++){
            if (votes[transactionId][_owners[i]] == Vote.VOTED_CONTRA)
                cancelCount = cancelCount.add(1);
        }

        if (cancelCount >= 2)
            transactions[transactionId].status = TrxStatus.REJECTED;
            emit TransactionClosed(transactionId, getVotesById(transactionId));
    }
    
    function repeatTrxExecution(uint transactionId) public exist(transactionId) available(transactionId) onlyOwner{
        require(isConfirmed(transactionId), "The transaction has not been confirmed or executed");
        _executeTransaction(transactionId);
    }
    
    // call has been separated into its own function in order to take advantage
    // of the Solidity's code generator to produce a loop that copies tx.data into memory.
    function external_call(address destination, bytes memory data, uint256 value) private returns (bool, bytes memory) {
        (bool success, bytes memory result) = destination.call{value: value}(data);
        return (success, result);
    }

    function changeOwner(address oldOwner, address newOwner) public onlyWallet{
        require(!isOwner[newOwner], "Already owner");
        require(newOwner != address(0));
        isOwner[oldOwner] = false;
        isOwner[newOwner] = true;
        for (uint8 i; i < _owners.length; i++){
            if (_owners[i] == oldOwner)
                _owners[i] = newOwner;
        }
    }
    
    function getTransactionById(uint256 transactionId) public view exist(transactionId) returns(Transaction memory){
        return transactions[transactionId];
    }
    
    function getOwners() public view returns(address[3] memory){
        return _owners;
    }
    
    function getVotesById(uint transactionId) public view exist(transactionId) returns(OwnerVote[3] memory _votes){
        for(uint8 i = 0; i < _owners.length; i++){
            _votes[i] = OwnerVote(_owners[i], votes[transactionId][_owners[i]]);
        }
    }
    
    function getAvailableToVoteTrxCount() public view returns(uint count){
        for (uint i = 0; i < transactionsLength(); i++){
            if(transactions[i].status == TrxStatus.PENDING || transactions[i].status == TrxStatus.ACCEPTED_FAILED)
                count = count.add(1);
        }
    }
    
    function getAllTransactions() public view returns(Transaction[] memory){
        return transactions;
    }
    
    function transactionsLength() public view returns(uint){
        return transactions.length;
    }
    
    function getTrxAndVotesById(uint transactionId) public view exist(transactionId) returns(Transaction memory, OwnerVote[3] memory){
        return (getTransactionById(transactionId), getVotesById(transactionId));
    }
}