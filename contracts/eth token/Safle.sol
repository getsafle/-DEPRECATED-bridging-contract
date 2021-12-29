// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract SafleToken is ERC20, Ownable {

    uint256 _totalSupply = 1000000000 * 10 ** 18;
    string constant _name = "Safle";
    string constant _symbol = "SAFLE";

    address public rootTunnelContract;

    // Allowance amounts on behalf of others
    mapping (address => mapping (address => uint256)) private allowances;
    
    using SafeMath for uint256;

    // whitelist and set the timelock address and distribute intial allocations
    constructor() ERC20(_name, _symbol) {
        _mint(address(this), _totalSupply);
    }
    
    /// @notice This function is used to revoke the admin access. The owner address with be set to 0x00..
    function revokeAdminAccess() public onlyOwner {
        return renounceOwnership();
    }

    function setRootContract(address contractAddress) external onlyOwner returns (bool) {
        rootTunnelContract = contractAddress;

        return true;
    }

    function burn(address account, uint256 amount) external {
        _burn(account, amount);
    }

    function mint(address account, uint256 amount) external {
        require(msg.sender == rootTunnelContract, "Safle:: Only root tunnel contract can call mint function");

        _mint(account, amount);
    }

    /**
     * @notice Transfer `amount` tokens from `msg.sender` to `recepient`
     * @param recepient The address of the destination account
     * @param amount The number of tokens to transfer
     * @return Whether or not the transfer succeeded
     */
    function transfer(address recepient, uint256 amount) override public returns (bool) {
        _transfer(msg.sender, recepient, amount);
        return true;
    }

    /**
     * @notice Transfer `amount` tokens from `src` to `dst`
     * @param src The address of the source account
     * @param dst The address of the destination account
     * @param amount The number of tokens to transfer
     * @return Whether or not the transfer succeeded
     */
    function transferFrom(address src, address dst, uint amount) override public returns (bool) {
        uint256 currentAllowance = allowances[src][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        unchecked {
            _approve(src, _msgSender(), currentAllowance - amount);
        }

        _transfer(src, dst, amount);

        return true;
    }

    /**
     * @notice Approve the passed address to spend the specified amount of tokens on behalf of msg.sender.
     * @param spender The address of the spending account
     * @param amount The number of tokens for allowance
     * @return Whether or not the approval succeeded
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) override internal {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /// returns the allowance for a spender
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return allowances[owner][spender];
    }

    /**
     * @notice increase the spender's allowance
     * @param spender The address of the spender
     * @param addedValue The value to be added
     * @return Whether or not the decrease allowance succeeded
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual override returns (bool) {
        _approve(_msgSender(), spender, allowances[_msgSender()][spender] + addedValue);
        return true;
    }

    /**
     * @notice decrease the spender's allowance
     * @param spender The address of the spender
     * @param subtractedValue The value to be subtracted
     * @return Whether or not the decrease allowance succeeded
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual override returns (bool) {
        uint256 currentAllowance = allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(_msgSender(), spender, currentAllowance - subtractedValue);
        }

        return true;
    }

}