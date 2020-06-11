pragma solidity ^0.5.16;

contract att{
    address private owner;
    mapping (address => uint8) private managers;

    modifier isOwner{
        require(owner == msg.sender,'not root');
        _;
    }

    modifier isManager{
        require(
            msg.sender == owner || managers[msg.sender] == 1,'not admin');
        _;
    }

    uint constant MIN_SIGNATURES = 3;
    uint private transactionIdx;

    struct Transaction {
        address from;
        address to;
        uint amount;
        uint8 signatureCount;
        mapping (address => uint8) signatures;
    }

    mapping (uint => Transaction) private transactions;
    uint[] private pendingTransactions;

    constructor() public{
        owner = msg.sender;
    }

    event DepositFunds(address from, uint amount);
    event TransferFunds(address to, uint amount);
    event TransactionCreated(
        address from,
        address to,
        uint amount,
        uint transactionId
        );

    function addManager(address manager) public isOwner{
        managers[manager] = 1;
    }

    function removeManager(address manager) public isOwner{
        managers[manager] = 0;
    }

    function () external payable{
        emit DepositFunds(msg.sender, msg.value);
    }

    function transferTo(address to,  uint amount)public isManager{
        require(address(this).balance >= amount,'not balace');
        uint transactionId = transactionIdx++;

        Transaction memory transaction;
        transaction.from = msg.sender;
        transaction.to = to;
        transaction.amount = amount;
        transaction.signatureCount = 0;
        transactions[transactionId] = transaction;
        pendingTransactions.push(transactionId);
        emit TransactionCreated(msg.sender, to, amount, transactionId);
    }

    function getPendingTransactions() public isManager view returns(uint[] memory){
        return pendingTransactions;
    }

    function signTransaction(uint transactionId) public isManager{
        Transaction storage transaction = transactions[transactionId];
        require(transaction.signatures[msg.sender]!=1,'alert');
        transaction.signatures[msg.sender] = 1;
        transaction.signatureCount++;

        if(transaction.signatureCount >= MIN_SIGNATURES){
            require(address(this).balance >= transaction.amount,'not balance');
            address(uint160(transaction.to)).transfer(transaction.amount);
            emit TransferFunds(transaction.to, transaction.amount);
            deleteTransactions(transactionId);
        }
    }

    function deleteTransactions(uint transacionId) public isManager{
        uint8 replace = 0;
        for(uint i = 0; i < pendingTransactions.length; i++){
            if(1==replace){
                pendingTransactions[i-1] = pendingTransactions[i];
            }else if(transacionId == pendingTransactions[i]){
                replace = 1;
            }
        }
        delete pendingTransactions[pendingTransactions.length - 1];
        pendingTransactions.length--;
        delete transactions[transacionId];
    }

    function walletBalance() public isManager view returns(uint){
        return address(this).balance;
    }
}