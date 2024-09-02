// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./AbstractStablecoinTokenV1.sol";
import "./Permissions.sol";
import "./Whitelistable.sol";
import "./Freezable.sol";
import "./Pausable.sol";
import "./Rescuable.sol";
import "./NativeCurrencyPaymentFallback.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

/**
 * @title StablecoinToken
 */
contract StablecoinToken is Initializable,
    NativeCurrencyPaymentFallback,
    AbstractStablecoinTokenV1,
    Pausable,
    Permissions,
    Whitelistable,
    Freezable,
    Rescuable
{
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;
    uint256 private _reserveBalance;

    string private _name;
    string private _symbol;
    string private _currency;
    uint8 private _decimals;

    //bool internal initialized;

    address internal _burnAccount;

    event Mint(address indexed minter, address indexed to, uint256 amount);
    event Burn(address indexed burner, uint256 amount);
    event ReserveBalanceChanged(uint256 newReserveBalance);
    event BurntAccountChanged(address indexed newAccount);
    event SeizeTransferFrom(
        address indexed from,
        address indexed to,
        uint256 value
    );

    constructor() {
        _disableInitializers();
    }

    modifier checkAccount(address _account) {
        if (_account != _burnAccount) {
            require(!_isFrozen(_account), "Freezable: account is frozen");
            require(
                !whitelistedStatus() || _isWhitelisted(_account),
                "Whitelistable: account not is whitelisted"
            );
        }
        _;
    }

    function initialize(
        string memory tokenName,
        string memory tokenSymbol,
        string memory tokenCurrency,
        uint8 tokenDecimals,
        address newCompliance,
        address newOperator,
        address newBurnAccount,
        bool whitelistStatus
    ) public initializer {
        // require(
        //     !initialized,
        //     "StablecoinToken: contract is already initialized"
        // );

        require(
            newBurnAccount != address(0),
            "StablecoinToken: burn account cannot be zero address"
        );

        _name = tokenName;
        _symbol = tokenSymbol;
        _currency = tokenCurrency;
        _decimals = tokenDecimals;

        _updateCompliance(newCompliance);
        _updateOperator(newOperator);
        if (whitelistStatus) {
            _enableWhitelisted();
        }

        _burnAccount = newBurnAccount;
        //initialized = true;
    }

    /**
     * @dev Implementation of pause method for permission control.
     * @notice called by the owner to pause, triggers stopped state.
     */
    function pause() external virtual override OnlyCompliance {
        _pause();
    }

    /**
     * @dev Implementation of unpause method for permission control.
     * @notice called by the owner to unpause, triggers stopped state.
     */
    function unpause() external virtual override OnlyCompliance {
        _unpause();
    }

    /**
     * @dev Implementation of freeze method for permission control.
     * @notice Adds account to frozen list.
     * @param _account The address to frozen list.
     */
    function freeze(
        address _account
    ) external virtual override whenNotPaused OnlyCompliance {
        _freeze(_account);
    }

    /**
     * @dev Implementation of unFreeze method for permission control.
     * @notice Removes account from frozen list.
     * @param _account The address to remove from the frozen list.
     */
    function unFreeze(
        address _account
    ) external virtual override whenNotPaused OnlyCompliance {
        _unFreeze(_account);
    }

    /**
     * @dev Implementation of whitelist method for permission control.
     * @notice Adds account to whitelist.
     * @param _account The address to whitelist.
     */
    function whitelist(
        address _account
    ) external virtual override whenNotPaused OnlyCompliance {
        _whitelist(_account);
    }

    /**
     * @dev Implementation of unWhitelist method for permission control.
     * @notice Removes account from whitelist.
     * @param _account The address to remove from the whitelist.
     */
    function unWhitelist(
        address _account
    ) external virtual override whenNotPaused OnlyCompliance {
        _unWhitelist(_account);
    }

    /**
     * @dev Implementation of disableWhitelisted method for permission control.
     * @notice Disable whitelist
     */
    function disableWhitelisted()
        external
        virtual
        override
        whenNotPaused
        OnlyCompliance
    {
        _disableWhitelisted();
    }

    /**
     * @dev Implementation of enableWhitelisted method for permission control.
     * @notice Enable whitelist
     */
    function enableWhitelisted()
        external
        virtual
        override
        whenNotPaused
        OnlyCompliance
    {
        _enableWhitelisted();
    }

    /**
     * @dev Implementation of rescueNativeCurrency method for permission control.
     * @notice Rescue Native Currency locked up in this contract.
     * @param to Recipient address
     * @param value value to withdraw
     */
    function rescueNativeCurrency(
        address to,
        uint256 value
    ) external virtual override whenNotPaused OnlyCompliance {
        _rescueNativeCurrency(to, value);
    }

    /**
     * @dev Implementation of rescueERC20 method for permission control.
     * @notice Rescue ERC20 tokens locked up in this contract.
     * @param tokenContract ERC20 token contract address
     * @param to Recipient address
     * @param amount Amount to withdraw
     */
    function rescueERC20(
        IERC20 tokenContract,
        address to,
        uint256 amount
    ) external virtual override whenNotPaused OnlyCompliance {
        _rescueERC20(tokenContract, to, amount);
    }

    /**
     * @dev Updates the reserve balance.
     * @param newReserveBalance the new reserve balance must be greater than or equal to total supply.
     */
    function updateReserveBalance(
        uint256 newReserveBalance
    ) external virtual whenNotPaused OnlyCompliance {
        _updateReserveBalance(newReserveBalance);
        emit ReserveBalanceChanged(newReserveBalance);
    }

    /**
     * @dev query reserve balance.
     */
    function reserveBalance() public view virtual returns (uint256) {
        return _reserveBalance;
    }

    /**
     * @dev Helper methods for updates reserve balance.
     * @param newReserveBalance the new reserve balance must be greater than or equal to total supply.
     */
    function _updateReserveBalance(uint256 newReserveBalance) internal virtual {
        require(
            newReserveBalance >= _totalSupply,
            "StablecoinToken: must be greater than or equal to total supply"
        );
        _reserveBalance = newReserveBalance;
    }

    /**
     * @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply. the total supply must be less than or equal to reserve balance.
     * @param to Account address for receiving balance. cannot be the zero address and unrestricted transfer.
     * @param amount amount of mint balance.
     */
    function mint(
        address to,
        uint256 amount
    )
        external
        virtual
        override
        whenNotPaused
        checkAccount(to)
        OnlyOperator
        returns (bool)
    {
        _mint(to, amount);
        emit Mint(_msgSender(), to, amount);
        return true;
    }

    /**
     * @dev The method of burn `burnAccount` balance.
     * @param amount amount of burn balance.
     */
    function burn(
        uint256 amount
    ) external virtual override whenNotPaused OnlyOperator {
        address account = _burnAccount;
        _burn(account, amount);
        emit Burn(account, amount);
    }

    /**
     * @dev seize transfer balance `from` to `to`.
     * @param from cannot be the zero address.
     * @param to cannot be the zero address.
     * @param amount Must be less than or equal to the `from` balance.
     */
    function seizeTransferFrom(
        address from,
        address to,
        uint256 amount
    ) external virtual override whenNotPaused OnlyCompliance returns (bool) {
        _transfer(from, to, amount);
        emit SeizeTransferFrom(from, to, amount);
        return true;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the _currency of the token, usually a shorter version of the
     * name.
     */
    function currency() public view virtual returns (string memory) {
        return _currency;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return _decimals;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(
        address account
    ) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(
        address to,
        uint256 amount
    )
        public
        virtual
        override
        whenNotPaused
        checkAccount(_msgSender())
        checkAccount(to)
        returns (bool)
    {
        address owner = _msgSender();
        _transfer(owner, to, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(
        address owner,
        address spender
    ) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * NOTE: If `amount` is the maximum `uint256`, the allowance is not updated on
     * `transferFrom`. This is semantically equivalent to an infinite approval.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(
        address spender,
        uint256 amount
    )
        public
        virtual
        override
        whenNotPaused
        checkAccount(_msgSender())
        checkAccount(spender)
        returns (bool)
    {
        address owner = _msgSender();
        _approve(owner, spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * NOTE: Does not update the allowance if the current allowance
     * is the maximum `uint256`.
     *
     * Requirements:
     *
     * - `from` and `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     * - the caller must have allowance for ``from``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    )
        public
        override
        whenNotPaused
        checkAccount(_msgSender())
        checkAccount(from)
        checkAccount(to)
        returns (bool)
    {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(
        address spender,
        uint256 addedValue
    )
        public
        virtual
        whenNotPaused
        checkAccount(_msgSender())
        checkAccount(spender)
        returns (bool)
    {
        address owner = _msgSender();
        _approve(owner, spender, allowance(owner, spender) + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(
        address spender,
        uint256 subtractedValue
    )
        public
        virtual
        whenNotPaused
        checkAccount(_msgSender())
        checkAccount(spender)
        returns (bool)
    {
        address owner = _msgSender();
        uint256 currentAllowance = allowance(owner, spender);
        require(
            currentAllowance >= subtractedValue,
            "ERC20: decreased allowance below zero"
        );
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `from` to `to`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     */
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(from, to, amount);

        uint256 fromBalance = _balances[from];
        require(
            fromBalance >= amount,
            "ERC20: transfer amount exceeds balance"
        );
        unchecked {
            _balances[from] = fromBalance - amount;
            // Overflow not possible: the sum of all balances is capped by totalSupply, and the sum is preserved by
            // decrementing then incrementing.
            _balances[to] += amount;
        }

        emit Transfer(from, to, amount);

        _afterTokenTransfer(from, to, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply. the total supply must be less than or equal to reserve balance.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;

        require(
            _totalSupply <= _reserveBalance,
            "StableToken:reserve balance limit"
        );

        unchecked {
            // Overflow not possible: balance + amount is at most totalSupply + amount, which is checked above.
            _balances[account] += amount;
        }
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(
            account != address(0),
            "ERC20: burn from the zero address"
        );

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
            // Overflow not possible: amount <= accountBalance <= totalSupply.
            _totalSupply -= amount;
        }

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Updates `owner` s allowance for `spender` based on spent `amount`.
     *
     * Does not update the allowance amount in case of infinite allowance.
     * Revert if not enough allowance is available.
     *
     * Might emit an {Approval} event.
     */
    function _spendAllowance(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(
                currentAllowance >= amount,
                "ERC20: insufficient allowance"
            );
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev Return the burn account.
     */
    function burnAccount() external view virtual returns (address) {
        return _burnAccount;
    }

    /**
     * @dev  Updates the burn account.
     * @param _account the new burn account.
     */
    function updateBurnAccount(
        address _account
    ) external virtual whenNotPaused OnlyCompliance {
        require(_account != address(0), "StablecoinToken: burn account cannot be zero address");
        require(
            _balances[_account] == 0,
            "StablecoinToken: old burn account balance must be zero"
        );
        _burnAccount = _account;
        emit BurntAccountChanged(_account);
    }
}
