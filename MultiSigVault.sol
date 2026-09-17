// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title MultiSigVault
 * @notice M-of-N Treasury Vault with Reentrancy Mutex and Circuit Breaker
 */
contract MultiSigVault {
    address[] public signers;
    mapping(address => bool) public isSigner;
    uint256 public requiredSignatures;
    bool public paused;
    uint256 private _status; // Reentrancy mutex lock (1 = UNLOCKED, 2 = LOCKED)

    struct Transaction {
        address payable to;
        uint256 value;
        bytes data;
        bool executed;
        uint256 confirmationCount;
    }

    Transaction[] public transactions;
    mapping(uint256 => mapping(address => bool)) public isConfirmed;

    event Deposit(address indexed sender, uint256 amount, uint256 balance);
    event SubmitTransaction(uint256 indexed txIndex, address indexed to, uint256 value, bytes data);
    event ConfirmTransaction(address indexed signer, uint256 indexed txIndex);
    event ExecuteTransaction(address indexed signer, uint256 indexed txIndex);
    event CircuitBreakerToggled(bool isPaused);

    modifier onlySigner() {
        require(isSigner[msg.sender], "MultiSigVault: Caller is not a signer");
        _;
    }

    modifier txExists(uint256 _txIndex) {
        require(_txIndex < transactions.length, "MultiSigVault: Tx does not exist");
        _;
    }

    modifier notExecuted(uint256 _txIndex) {
        require(!transactions[_txIndex].executed, "MultiSigVault: Tx already executed");
        _;
    }

    modifier notConfirmed(uint256 _txIndex) {
        require(!isConfirmed[_txIndex][msg.sender], "MultiSigVault: Tx already confirmed");
        _;
    }

    modifier whenNotPaused() {
        require(!paused, "MultiSigVault: Contract is paused");
        _;
    }

    modifier nonReentrant() {
        require(_status != 2, "MultiSigVault: ReentrancyGuard reentrant call");
        _status = 2;
        _;
        _status = 1;
    }

    constructor(address[] memory _signers, uint256 _requiredSignatures) payable {
        require(_signers.length > 0, "MultiSigVault: Signers required");
        require(
            _requiredSignatures > 0 && _requiredSignatures <= _signers.length,
            "MultiSigVault: Invalid quorum threshold"
        );

        for (uint256 i = 0; i < _signers.length; i++) {
            address signer = _signers[i];
            require(signer != address(0), "MultiSigVault: Zero address signer");
            require(!isSigner[signer], "MultiSigVault: Duplicate signer");

            isSigner[signer] = true;
            signers.push(signer);
        }

        requiredSignatures = _requiredSignatures;
        _status = 1;
    }

    receive() external payable {
        emit Deposit(msg.sender, msg.value, address(this).balance);
    }

    function submitTransaction(
        address payable _to,
        uint256 _value,
        bytes memory _data
    ) public onlySigner whenNotPaused returns (uint256) {
        uint256 txIndex = transactions.length;

        transactions.push(
            Transaction({
                to: _to,
                value: _value,
                data: _data,
                executed: false,
                confirmationCount: 0
            })
        );

        emit SubmitTransaction(txIndex, _to, _value, _data);
        confirmTransaction(txIndex);
        return txIndex;
    }

    function confirmTransaction(uint256 _txIndex)
        public
        onlySigner
        txExists(_txIndex)
        notExecuted(_txIndex)
        notConfirmed(_txIndex)
        whenNotPaused
    {
        Transaction storage transaction = transactions[_txIndex];
        transaction.confirmationCount += 1;
        isConfirmed[_txIndex][msg.sender] = true;

        emit ConfirmTransaction(msg.sender, _txIndex);
    }

    function executeTransaction(uint256 _txIndex)
        public
        onlySigner
        txExists(_txIndex)
        notExecuted(_txIndex)
        whenNotPaused
        nonReentrant
    {
        Transaction storage transaction = transactions[_txIndex];

        require(
            transaction.confirmationCount >= requiredSignatures,
            "MultiSigVault: Quorum threshold not met"
        );

        transaction.executed = true;

        (bool success, ) = transaction.to.call{value: transaction.value}(transaction.data);
        require(success, "MultiSigVault: Transaction execution failed");

        emit ExecuteTransaction(msg.sender, _txIndex);
    }

    function toggleEmergencyPause() external onlySigner {
        paused = !paused;
        emit CircuitBreakerToggled(paused);
    }

    function getTransactionCount() public view returns (uint256) {
        return transactions.length;
    }
}