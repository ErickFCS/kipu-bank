// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

/**
 * @title KipuBank
 * @notice A simple banking contract for deposits and capped withdrawals.
 */
contract KipuBank {
    /*///////////////////////////////////
          Type declarations
    ///////////////////////////////////*/
    /// @notice Defines the type of balance update operation.
    enum Operation {
        Extract,
        Deposit
    }

    /*///////////////////////////////////
           Immutable variables
    ///////////////////////////////////*/
    /// @notice Total deposit value allowed (bank limit).
    uint256 public immutable i_bankCap;
    /// @notice Biggest value allowed for any individual extract.
    uint256 public immutable i_maxExtract;

    /*///////////////////////////////////
           State variables
    ///////////////////////////////////*/
    /// @notice Mapping for storing user balance relations.
    mapping(address user => uint256 balance) private s_accounts;
    /// @notice Total deposits count.
    uint256 public s_totalDeposits;
    /// @notice Total quantity of successful deposits done.
    uint256 public s_totalSuccessfulQuantityOfDeposits;
    /// @notice Total quantity of successful extracts done.
    uint256 public s_totalSuccessfulQuantityOfExtracts;

    /*///////////////////////////////////
               Events
    ///////////////////////////////////*/
    /// @notice Emitted when there is a successful extract.
    /// @param wallet The address of the account that extracted.
    /// @param quantity The amount of Ether extracted.
    event KipuBank_SuccessfulExtract(address indexed wallet, uint256 quantity);
    /// @notice Emitted when there is a successful deposit.
    /// @param wallet The address of the account that deposited.
    /// @param quantity The amount of Ether deposited.
    event KipuBank_SuccessfulDeposit(address indexed wallet, uint256 quantity);
    /// @notice Emitted after any successful balance update.
    /// @param wallet The address of the account whose balance was updated.
    /// @param quantity The new total balance of the account.
    event KipuBank_SuccessfulBalanceUpdate(address indexed wallet, uint256 quantity);

    /*///////////////////////////////////
                Errors
    ///////////////////////////////////*/
    /// @notice Emitted when there is a failed extract.
    /// @param wallet The address that attempted the extract.
    /// @param quantity The amount that was attempted.
    /// @param reason Short explanation for the failure.
    error KipuBank_FailedExtract(
        address wallet,
        uint256 quantity,
        string reason
    );
    /// @notice Emitted when there is a failed deposit.
    /// @param wallet The address that attempted the deposit.
    /// @param quantity The amount that was attempted.
    /// @param reason Short explanation for the failure.
    error KipuBank_FailedDeposit(
        address wallet,
        uint256 quantity,
        string reason
    );

    /*///////////////////////////////////
                Modifiers
    ///////////////////////////////////*/
    /// @notice Verifies the bank cap limit.
    /// @param _value The value to check against the cap.
    modifier underBankCap(uint256 _value) {
        if (s_totalDeposits + _value > i_bankCap)
            revert KipuBank_FailedDeposit(
                msg.sender,
                _value,
                "Cap reached" 
            );
        _;
    }
    /// @notice Verifies the max extract limit and the account balance.
    /// @param _quantity The quantity to check.
    modifier validExtract(uint256 _quantity) {
        if (_quantity > i_maxExtract)
            revert KipuBank_FailedExtract(
                msg.sender,
                _quantity,
                "Limit exceeded" 
            );
        if (_quantity > s_accounts[msg.sender])
            revert KipuBank_FailedExtract(
                msg.sender,
                _quantity,
                "Insufficient balance" 
            );
        _;
    }

    /*///////////////////////////////////
                Functions
    ///////////////////////////////////*/

    /*/////////////////////////
            constructor
    /////////////////////////*/
    /// @notice Sets the values for the contract's immutable constraints.
    /// @param _maxExtract The biggest value allowed for any individual extract.
    /// @param _bankCap The total deposit value allowed.
    constructor(uint256 _maxExtract, uint256 _bankCap) {
        i_maxExtract = _maxExtract;
        i_bankCap = _bankCap;
        // State variables are already 0 by default, no need to set them here.
    }

    /*/////////////////////////
        Receive&Fallback
    /////////////////////////*/
    /// @notice Prevents direct deposits.
    receive() external payable {
        revert KipuBank_FailedDeposit(
            msg.sender,
            msg.value,
            "Use deposit function" 
        );
    }

    /*/////////////////////////
            external
    /////////////////////////*/
    /// @notice Deposits to the sender account, respecting the bank cap.
    function depositToAccount() external payable underBankCap(msg.value) {
        // Check to prevent zero-value deposits
        if (msg.value == 0) {
            revert KipuBank_FailedDeposit(
                msg.sender,
                0,
                "Zero deposit"
            );
        }

        // Use unchecked since the modifier already verified safety
        unchecked {
            s_totalDeposits += msg.value;
            s_totalSuccessfulQuantityOfDeposits += 1;
        }

        // Update state
        _updateAccountBalance(msg.value, Operation.Deposit);

        // Emit event
        emit KipuBank_SuccessfulDeposit(msg.sender, msg.value);
    }
    
    /// @notice Extracts to the sender wallet within the max extract limit.
    /// @param _quantity The amount to extract.
    function extractFromAccount(
        uint256 _quantity
    ) external validExtract(_quantity) {
        // Update state BEFORE interaction (CEI Pattern Fix)
        _updateAccountBalance(_quantity, Operation.Extract);
        
        // Use unchecked for simple increment
        unchecked {
            s_totalSuccessfulQuantityOfExtracts += 1;
        }

        // Send Ether
        (bool success, ) = msg.sender.call{value: _quantity}("");

        // Post-interaction check
        if (!success)
            revert KipuBank_FailedExtract(
                msg.sender,
                _quantity,
                "Transfer failed"
            );
        
        // Emit event
        emit KipuBank_SuccessfulExtract(msg.sender, _quantity);
    }

    /*/////////////////////////
            internal
    /////////////////////////*/
    /// @notice Updates the value of an account balance.
    /// @param _quantity The amount to add or subtract.
    /// @param _operation The type of operation (Extract or Deposit).
    function _updateAccountBalance(
        uint256 _quantity,
        Operation _operation
    ) private {
        // Load and modify the state variable in memory first
        uint256 newBalance;
        uint256 currentBalance = s_accounts[msg.sender];

        if (_operation == Operation.Extract) {
            newBalance = currentBalance - _quantity; 
        } else {
            newBalance = currentBalance + _quantity;
        }

        // Write back to storage
        s_accounts[msg.sender] = newBalance;

        emit KipuBank_SuccessfulBalanceUpdate(
            msg.sender,
            newBalance
        );
    }

    /*/////////////////////////
        View & Pure
    /////////////////////////*/
    /// @notice Get the balance of an account.
    /// @return balance The balance of the sender's account.
    function getBalance() external view returns (uint256 balance) {
        balance = s_accounts[msg.sender];
    }
}