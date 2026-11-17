// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

/// @notice Minimal ERC-20 interface (avoids an OpenZeppelin dependency).
interface IERC20 {
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);
}

/// @title PayLink — payment requests ("pay links") for tUSD8 on QDay Aevum
/// @notice A merchant creates a payment request (amount + memo). Anyone with the
///         link can pay it: the exact tUSD8 amount is pulled from the payer
///         straight to the merchant via transferFrom. No funds are ever held
///         by this contract, so there is nothing to custody or drain.
/// @dev    Designed for the Aevum Builder Challenge #1. Testnet only.
contract PayLink {
    struct Request {
        address merchant;
        uint256 amount; // in tUSD8 base units (6 decimals)
        string memo;
        address payer; // address(0) until paid
        bool paid;
        bool cancelled;
    }

    IERC20 public immutable token;
    uint256 public nextId = 1;

    mapping(uint256 => Request) private _requests;

    event RequestCreated(uint256 indexed id, address indexed merchant, uint256 amount, string memo);
    event RequestPaid(uint256 indexed id, address indexed payer, uint256 amount);
    event RequestCancelled(uint256 indexed id);

    error ZeroAmount();
    error NotFound();
    error AlreadyPaid();
    error AlreadyCancelled();
    error NotMerchant();
    error TransferFailed();

    constructor(address token_) {
        token = IERC20(token_);
    }

    /// @notice Create a payment request. Returns the request id used in the pay link.
    function createRequest(uint256 amount, string calldata memo) external returns (uint256 id) {
        if (amount == 0) revert ZeroAmount();
        id = nextId++;
        _requests[id] = Request({
            merchant: msg.sender,
            amount: amount,
            memo: memo,
            payer: address(0),
            paid: false,
            cancelled: false
        });
        emit RequestCreated(id, msg.sender, amount, memo);
    }

    /// @notice Pay an open request. Caller must have approved this contract
    ///         for at least the request amount of tUSD8 first.
    function pay(uint256 id) external {
        Request storage r = _requests[id];
        if (r.merchant == address(0)) revert NotFound();
        if (r.paid) revert AlreadyPaid();
        if (r.cancelled) revert AlreadyCancelled();

        r.paid = true;
        r.payer = msg.sender;

        // Emit before the external call (forge lint: reentrancy-events).
        // Safe here: a failed transfer reverts the whole tx, discarding the log.
        emit RequestPaid(id, msg.sender, r.amount);
        if (!token.transferFrom(msg.sender, r.merchant, r.amount)) revert TransferFailed();
    }

    /// @notice Cancel an unpaid request. Only the merchant who created it.
    function cancel(uint256 id) external {
        Request storage r = _requests[id];
        if (r.merchant == address(0)) revert NotFound();
        if (msg.sender != r.merchant) revert NotMerchant();
        if (r.paid) revert AlreadyPaid();
        if (r.cancelled) revert AlreadyCancelled();
        r.cancelled = true;
        emit RequestCancelled(id);
    }

    function getRequest(uint256 id) external view returns (Request memory) {
        if (_requests[id].merchant == address(0)) revert NotFound();
        return _requests[id];
    }
}
