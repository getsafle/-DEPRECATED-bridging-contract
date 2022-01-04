// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

// IFxMessageProcessor represents interface to process message
interface IFxMessageProcessor {
    function processMessageFromRoot(
        uint256 stateId,
        address rootMessageSender,
        bytes calldata data
    ) external;
}

/**
 * @notice Mock child tunnel contract to receive and send message from L2
 */
contract FxBaseChildTunnel is IFxMessageProcessor {
    // MessageTunnel on L1 will get data from this event
    event MessageSent(bytes message);

    // fx child
    address public fxChild;

    using SafeERC20 for IERC20;

    // address of the ERC20 token
    IERC20 private _token;

    // fx root tunnel
    address public fxRootTunnel;

    uint256 _lockedTokens;

    constructor(address _fxChild, address token_) {
        fxChild = _fxChild;
        _token = IERC20(token_);
    }

    // Sender must be fxRootTunnel in case of ERC20 tunnel
    modifier validateSender(address sender) {
        require(sender == fxRootTunnel, "FxBaseChildTunnel: INVALID_SENDER_FROM_ROOT");
        _;
    }

    // set fxRootTunnel if not set already
    function setFxRootTunnel(address _fxRootTunnel) external {
        require(fxRootTunnel == address(0x0), "FxBaseChildTunnel: ROOT_TUNNEL_ALREADY_SET");
        fxRootTunnel = _fxRootTunnel;
    }

    function withdraw(uint256 amount) public returns (bool) {
        bytes memory accountRef = abi.encode(msg.sender, amount);
        // Pull token from owner to bridge contract (owner must set approval before calling withdraw)
        // using msg.sender, the owner must call withdraw, but we can make delegated transfers with sender
        // address as parameter.
        require(_token.transferFrom(msg.sender, address(this), amount), "Failed to burn");
        _sendMessageToRoot(accountRef);
        emit Locked(msg.sender, amount, accountRef);
        return true;
    }

    function processMessageFromRoot(
        uint256 stateId,
        address rootMessageSender,
        bytes calldata data
    ) validateSender(rootMessageSender) external override {
        require(msg.sender == fxChild, "FxBaseChildTunnel: INVALID_SENDER");
        _processMessageFromRoot(stateId, rootMessageSender, data);
    }

    /**
     * @notice Emit message that can be received on Root Tunnel
     * @dev Call the internal function when need to emit message
     * @param message bytes message that will be sent to Root Tunnel
     * some message examples -
     *   abi.encode(tokenId);
     *   abi.encode(tokenId, tokenMetadata);
     *   abi.encode(messageType, messageData);
     */
    function _sendMessageToRoot(bytes memory message) internal {
        emit MessageSent(message);
    }

    /**
     * @notice Process message received from Root Tunnel
     * @dev function needs to be implemented to handle message as per requirement
     * This is called by onStateReceive function.
     * Since it is called via a system call, any event will not be emitted during its execution.
     * @param stateId unique state id
     * @param sender root message sender
     * @param message bytes message that was sent from Root Tunnel
     */
    function _processMessageFromRoot(uint256 stateId, address sender, bytes memory message) internal {
        (address _recepient, uint256 value) = abi.decode(message, (address, uint256));
        emit ProcessMessageFromRoot(_recepient, value, message);
        _unlockTokens(_recepient, value);
    }

    function _unlockTokens(address receiver, uint256 amount) internal {
        _token.safeTransfer(receiver, amount);
        emit Unlocked(receiver, amount);
    }

    event Unlocked(address receiver, uint256 amount);
    event ProcessMessageFromRoot(address _recepient, uint256 value, bytes message);
    event Locked(address sender, uint256 value, bytes message);
}