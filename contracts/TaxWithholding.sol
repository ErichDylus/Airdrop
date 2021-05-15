//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/** FOR DEMONSTRATION ONLY, not recommended to be used for any purpose and provided with no warranty whatsoever
 *  @dev split lump sum income and send portion to tax withholding wallet and remainder to 'checking account wallet'
 *  provides rough estimate, division intricacies in process
 */
 
interface IERC20 {

    /**
     * @dev Returns the amount of tokens owned by account.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to recipient
     * Returns a boolean value indicating whether the operation succeeded
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. May not be an issue since tax and checking addresses should both be controlled by owner
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     * Emits a {Transfer} event.
     */
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to another (`to`).
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract TaxWithholding {
    
    address payable owner;
    address payable taxes;
    address payable checking;
    uint256 income;
    
    modifier onlyOwner() { //restricts to agent (creator of escrow contract) or internal calls
    require(msg.sender == owner, "This may only be called by owner");
    _;
    }
    
    //owner designates wallets for taxes and 'checking' accounts
    constructor(address payable _taxes, address payable _checking) payable {
      require(_taxes != 0 && _checking != 0 , "Submit valid tax and checking wallet addresses");
      owner = payable(address(msg.sender));
      taxes = _taxes;
      checking = _checking;
      
    }
    
    function withholdTax(string memory _description, uint256 _income, uint8 _taxRate, IERC20 tokenAddress) private returns(uint256, uint256) {
        require(_taxRate > 0 && _taxRate < 100, "Submit tax rate percentage as whole number, for example 25");
        tokenAddress.transfer(address(this), _income); // send gross income to this contract
        uint256 _taxedAmt = (uint256(_income/uint256(_taxRate)));
        uint256 _afterTaxAmt = _income - _taxedAmt;
		tokenAddress.transferFrom(address(this), taxes, _taxedAmt);
		tokenAddress.transferFrom(address(this), checking, _afterTaxAmt);
        return(IERC20.balanceOf(taxes), IERC20.balanceOf(checking));
    }
}
