pragma solidity ^0.5.11;


contract MultiSignWallet {

    //state variables

    //store owners
    address[] public owners;
    // store number of confirmation required
    uint public numConfirmationsRequired;
    // keep track owners
    mapping(address => bool) public isOwner;

    //Event
    event SubmitTransaction(address indexed owner,
                            uint indexed txIndex,
                            address indexed to,
                            uint value,
                            bytes data);

    // events in solidity are the interfaces with EVM loggin functionalities
    // event is a way of communicating with the client side and the smart contracts deployed BC;
    event ConfirmTransaction(address indexed owner, uint indexed txIndex);
    event ExecuteTransaction(address indexed owner, uint indexed txIndex);
    event RevokeTransaction(address indexed owner, uint indexed txIndex);
    event Deposit (address indexed owner, uint amount, uint balance);

    // create struck of transaction and store it inside the array of transactions.
    struct Transaction {
        address to;
        uint value;
        bytes data;
        bool executed; // => check if the transaction is stored or not
        mapping(address => bool) isConfirmed; // => when the owner approuve transations we need to store that in mapping value;
        uint numConfirmations; // => num of approuvals
    }

    // keep track of all transactions type of Transaction
    Transaction[] public transactions;


//****************************** modifiers ***************************************//
    modifier txExists(uint _txIndex) {
        require (_txIndex <= transactions.length, "transaction already exists");
        _;
    }

    modifier notConfirmed (uint _txIndex) {
        require(!transactions[_txIndex].isConfirmed[msg.sender], "transaction already confirmed");
        _;
    }


    modifier notExcuted(uint _txIndex) {
        require(!transactions[_txIndex].executed, "transaction already executed");
        _;
    }

    modifier onlyOwner () {
        require(isOwner[msg.sender], "not the owner");
        _;
    }


    
    //****************************** constructor method ***********************//

    constructor (address[] memory _owners,uint _numConfirmationsRequired) public {

        require(_owners.length > 0, "owner required");
        require(_numConfirmationsRequired > 0 && _numConfirmationsRequired <= _owners.length);

        // store each owner in the owners array
        for(uint i = 0; i < _owners.length; i++) {
                address owner = _owners[i];
            //check if the owner address is valid
            require(owner != address(0), "address in not valid");
            // check that there is not a duplicate owner
            require(!isOwner[owner], "owner is not unique");

            isOwner[owner] = true;
            owners.push(owner);
        }
        numConfirmationsRequired = _numConfirmationsRequired;
    }

    //****************************** Deposit ***********************//

    function () payable external {
        emit Deposit(msg.sender, msg.value, address(this).balance);
    }

    //****************************** submit transactions ***********************//

    function submitTransactions(address _to, uint _value, bytes memory _data)
    onlyOwner public {
        
        // Get the current transaction using transactions array
        uint txIndex = transactions.length; //0
         
        // push the data to transactions array
        transactions.push(Transaction({
            to : _to,
            value : _value,
            data : _data,
            executed: false,
            numConfirmations:0
        }));

        // _to _value _data represent the input that was add to this function
        emit SubmitTransaction(msg.sender, txIndex, _to, _value, _data);

    }




    //****************************** confirmation transactions ***********************//

    function confirmTransaction (uint _txIndex) public 
    onlyOwner
    notExcuted(_txIndex)
    notConfirmed(_txIndex)
    txExists(_txIndex) {
    
    //to update the transaction struct we need to get the transaction at txIndex
    Transaction storage transaction = transactions[_txIndex];

        transaction.numConfirmations += 1; 
        transaction.isConfirmed[msg.sender] = true;
        emit ConfirmTransaction(msg.sender, _txIndex);
    }


    //****************************** confirmation transactions ***********************//
    
    function executeTransaction (uint _txIndex)
    onlyOwner
    notExcuted(_txIndex)
    txExists(_txIndex) public {
        
        Transaction storage transaction = transactions[_txIndex];

        // check if the number of confirmation required is correct
        require(
            transaction.numConfirmations >= numConfirmationsRequired,
            "cannot excute transaction"
            );

        transaction.executed = true;

        // excute the transaction using call methods
        (bool success, ) = transaction.to.call.value(transaction.value)(transaction.data);
        require(success, "transaction failed");
        
        emit ExecuteTransaction(msg.sender, _txIndex);
    }

    //****************************** Revoke Transaction***********************//
    function revokeTransaction (uint _txIndex)
     public
    notExcuted(_txIndex)
    onlyOwner
    txExists(_txIndex) {

        Transaction storage transaction = transactions[_txIndex];

        // msg.sender has already confirm the trsanction
        require(transactions[_txIndex].isConfirmed[msg.sender], "transaction not confirmed");

        transaction.isConfirmed[msg.sender] = false;
        transaction.numConfirmations -= 1;
        emit RevokeTransaction(msg.sender, _txIndex);

    }


    //****************************** Get Owners***********************//
    function getOwner() public view returns (address[] memory) {
        return owners;
    }

    //****************************** Get Transaction count***********************//
    function getTransactionCount() public view returns (uint) {
        return transactions.length;
    }

    //****************************** Get Transaction ***********************//
    function getTransaction(uint _txIndex) public view returns (
        address to, uint value, bytes memory data, bool executed, uint numConfirmations) {
            
    Transaction storage transaction = transactions[_txIndex];
        return (
            transaction.to,
            transaction.value,
            transaction.data,
            transaction.executed,
            transaction.numConfirmations
        );
    
    }

}

