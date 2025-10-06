// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

contract KipuBank {
    /*///////////////////////////////////
          Type declarations
    ///////////////////////////////////*/
    /// @notice This is an enum for the update balance private function.
    enum Operation {
        Extract,
        Deposit
    }

    /*///////////////////////////////////
           Immutable variables
    ///////////////////////////////////*/
    /// @notice Total deposit value allowed, once reachec, no more deposits will be accepted.
    uint256 public immutable i_bankCap;
    /// @notice Biggest value allowed for any individual extract.
    uint256 public immutable i_maxExtract;

    /*///////////////////////////////////
           State variables
    ///////////////////////////////////*/
    /// @notice Mapping for storing user balance relations.
    mapping(address user => uint256 balance) private s_accounts;
    /// @notice Total deposits count.
    uint256 public s_totalDeposits = 0;
    /// @notice Total quantity of successful deposits done.
    uint256 public s_totalSuccessfulQuantityOfDeposits = 0;
    /// @notice Total quantity of successful extracts done.
    uint256 public s_totalSuccessfulQuantityOfExtracts = 0;

    /*///////////////////////////////////
               Events
    ///////////////////////////////////*/
    /// @notice Emmited event when there is a successful extract.
    event KipuBank_SuccessfulExtract(address wallet, uint256 quantity);
    /// @notice Emmited event when there is a successful deposit.
    event KipuBank_SuccessfulDeposit(address wallet, uint256 quantity);
    /// @notice Emmited event when there is a successful deposit.
    event KipuBank_SuccessfulBalanceUpdate(address wallet, uint256 quantity);

    /*///////////////////////////////////
                errors
    ///////////////////////////////////*/
    /// @notice Emmited event when there is a failed extract.
    error KipuBank_FailedExtract(
        address wallet,
        uint256 quantity,
        string reason
    );
    /// @notice Emmited event when there is a failed deposit.
    error KipuBank_FailedDeposit(
        address wallet,
        uint256 quantity,
        string reason
    );

    /*///////////////////////////////////
                Modifiers
    ///////////////////////////////////*/
    /// @notice Verifier for the bank cap limit.
    modifier underBankCap(uint256 _value) {
        if (s_totalDeposits + _value > i_bankCap)
            revert KipuBank_FailedDeposit(
                msg.sender,
                _value,
                "Bank cap reached"
            );
        _;
    }
    /// @notice Verifier for the max extract limit and the account balance.
    modifier validExtract(uint256 _quantity) {
        if (_quantity > i_maxExtract)
            revert KipuBank_FailedExtract(
                msg.sender,
                _quantity,
                "Quantity bigger than the max extract limit."
            );
        if (_quantity > s_accounts[msg.sender])
            revert KipuBank_FailedExtract(
                msg.sender,
                _quantity,
                "Quantity bigger than the account balance."
            );
        _;
    }

    /*///////////////////////////////////
                Functions
    ///////////////////////////////////*/

    /*/////////////////////////
            constructor
    /////////////////////////*/
    /// @notice Set the values for the constrains for this contract.
    constructor(uint256 _maxExtract, uint256 _bankCap) {
        i_maxExtract = _maxExtract;
        i_bankCap = _bankCap;
    }

    /*/////////////////////////
        Receive&Fallback
    /////////////////////////*/
    /// @notice Prevents direct deposits.
    receive() external payable {
        revert KipuBank_FailedDeposit(
            msg.sender,
            msg.value,
            "Direct deposits not allowed. Use depositToAccount()"
        );
    }

    /*/////////////////////////
            external
    /////////////////////////*/
    /// @notice Deposit to the sender account and stop it the bank cap is reached.
    function depositToAccount() external payable underBankCap(msg.value) {
        s_totalDeposits += msg.value;
        _updateAccountBalance(msg.value, Operation.Deposit);
        s_totalSuccessfulQuantityOfDeposits += 1;

        emit KipuBank_SuccessfulDeposit(msg.sender, msg.value);
    }
    /// @notice Extract to the sender wallet withing the max extract limit.
    function extractFromAccount(
        uint256 _quantity
    ) external validExtract(_quantity) {
        _updateAccountBalance(_quantity, Operation.Extract);
        (bool success, ) = msg.sender.call{value: _quantity}("");
        if (!success)
            revert KipuBank_FailedExtract(
                msg.sender,
                _quantity,
                "Operation failed"
            );
        s_totalSuccessfulQuantityOfExtracts += 1;
        emit KipuBank_SuccessfulExtract(msg.sender, _quantity);
    }

    /*/////////////////////////
            public
    /////////////////////////*/

    /*/////////////////////////
            internal
    /////////////////////////*/

    /*/////////////////////////
            private
    /////////////////////////*/
    /// @notice Update the value of an account balance.
    function _updateAccountBalance(
        uint256 _quantity,
        Operation _operation
    ) private {
        if (_operation == Operation.Extract)
            s_accounts[msg.sender] -= _quantity;
        else s_accounts[msg.sender] += _quantity;

        emit KipuBank_SuccessfulBalanceUpdate(
            msg.sender,
            s_accounts[msg.sender]
        );
    }

    /*/////////////////////////
        View & Pure
    /////////////////////////*/
    /// @notice Get the balance of an account.
    function getBalance() external view returns (uint256 balance) {
        balance = s_accounts[msg.sender];
    }
}
