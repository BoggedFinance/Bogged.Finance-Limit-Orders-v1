/**   Limit Orders for Pancakeswap, Copyright BogTools 2021.
 *
 *    This program is free software: you can redistribute it and/or modify
 *    it under the terms of the GNU Affero General Public License as
 *    published by the Free Software Foundation, either version 3 of the
 *    License, or (at your option) any later version.
 *
 *    This program is distributed in the hope that it will be useful,
 *    but WITHOUT ANY WARRANTY; without even the implied warranty of
 *    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *    GNU Affero General Public License for more details.
 *
 *    You should have received a copy of the GNU Affero General Public License
 *    along with this program.  If not, see <https://www.gnu.org/licenses/>.
**/

pragma solidity ^0.7.4;

/**
 * $$$$$$$\                   $$$$$$$$\                  $$\           
 * $$  __$$\                  \__$$  __|                 $$ |          
 * $$ |  $$ | $$$$$$\   $$$$$$\  $$ | $$$$$$\   $$$$$$\  $$ | $$$$$$$\ 
 * $$$$$$$\ |$$  __$$\ $$  __$$\ $$ |$$  __$$\ $$  __$$\ $$ |$$  _____|
 * $$  __$$\ $$ /  $$ |$$ /  $$ |$$ |$$ /  $$ |$$ /  $$ |$$ |\$$$$$$\  
 * $$ |  $$ |$$ |  $$ |$$ |  $$ |$$ |$$ |  $$ |$$ |  $$ |$$ | \____$$\ 
 * $$$$$$$  |\$$$$$$  |\$$$$$$$ |$$ |\$$$$$$  |\$$$$$$  |$$ |$$$$$$$  |
 * \_______/  \______/  \____$$ |\__| \______/  \______/ \__|\_______/ 
 *                     $$\   $$ |                                      
 *                     \$$$$$$  |                                      
 *                      \______/
 * 
 * BogTools / Bogged Finance
 * 
 * Website: 
 *  - https://bogtools.io
 *  - https://bogged.finance
 * 
 * Telegram: https://t.me/bogtools
 */

/**
 * Standard SafeMath, stripped down to just add/sub/mul/div
 */
library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }
}

/**
 * BEP20 standard interface.
 */
interface IBEP20 {
    function totalSupply() external view returns (uint256);
    function decimals() external view returns (uint8);
    function symbol() external view returns (string memory);
    function name() external view returns (string memory);
    function getOwner() external view returns (address);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address _owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

library PancakeLibrary {
    using SafeMath for uint;

    // returns sorted token addresses, used to handle return values from pairs sorted in this order
    function sortTokens(address tokenA, address tokenB) internal pure returns (address token0, address token1) {
        require(tokenA != tokenB, 'PancakeLibrary: IDENTICAL_ADDRESSES');
        (token0, token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        require(token0 != address(0), 'PancakeLibrary: ZERO_ADDRESS');
    }

    // calculates the CREATE2 address for a pair without making any external calls
    function pairFor(address factory, address tokenA, address tokenB) internal pure returns (address pair) {
        (address token0, address token1) = sortTokens(tokenA, tokenB);
        pair = address(uint(keccak256(abi.encodePacked(
                hex'ff',
                factory,
                keccak256(abi.encodePacked(token0, token1)),
                hex'd0d4c4cd0848c93cb4fd1f498d7013ee6bfb25783ea21593d5834f5d250ece66' // init code hash
            ))));
    }

    // fetches and sorts the reserves for a pair
    function getReserves(address factory, address tokenA, address tokenB) internal view returns (uint reserveA, uint reserveB) {
        (address token0,) = sortTokens(tokenA, tokenB);
        pairFor(factory, tokenA, tokenB);
        (uint reserve0, uint reserve1,) = IPancakePair(pairFor(factory, tokenA, tokenB)).getReserves();
        (reserveA, reserveB) = tokenA == token0 ? (reserve0, reserve1) : (reserve1, reserve0);
    }

    // given some amount of an asset and pair reserves, returns an equivalent amount of the other asset
    function quote(uint amountA, uint reserveA, uint reserveB) internal pure returns (uint amountB) {
        require(amountA > 0, 'PancakeLibrary: INSUFFICIENT_AMOUNT');
        require(reserveA > 0 && reserveB > 0, 'PancakeLibrary: INSUFFICIENT_LIQUIDITY');
        amountB = amountA.mul(reserveB) / reserveA;
    }

    // given an input amount of an asset and pair reserves, returns the maximum output amount of the other asset
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) internal pure returns (uint amountOut) {
        require(amountIn > 0, 'PancakeLibrary: INSUFFICIENT_INPUT_AMOUNT');
        require(reserveIn > 0 && reserveOut > 0, 'PancakeLibrary: INSUFFICIENT_LIQUIDITY');
        
        // uniswap
        //uint amountInWithFee = amountIn.mul(997);
        
        //pancakeswap
        uint amountInWithFee = amountIn.mul(998);
        
        uint numerator = amountInWithFee.mul(reserveOut);
        uint denominator = reserveIn.mul(1000).add(amountInWithFee);
        amountOut = numerator / denominator;
    }

    // given an output amount of an asset and pair reserves, returns a required input amount of the other asset
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) internal pure returns (uint amountIn) {
        require(amountOut > 0, 'PancakeLibrary: INSUFFICIENT_OUTPUT_AMOUNT');
        require(reserveIn > 0 && reserveOut > 0, 'PancakeLibrary: INSUFFICIENT_LIQUIDITY');
        uint numerator = reserveIn.mul(amountOut).mul(1000);
        uint denominator = reserveOut.sub(amountOut).mul(998);
        amountIn = (numerator / denominator).add(1);
    }

    // performs chained getAmountOut calculations on any number of pairs
    function getAmountsOut(address factory, uint amountIn, address[] memory path) internal view returns (uint[] memory amounts) {
        require(path.length >= 2, 'PancakeLibrary: INVALID_PATH');
        amounts = new uint[](path.length);
        amounts[0] = amountIn;
        for (uint i; i < path.length - 1; i++) {
            (uint reserveIn, uint reserveOut) = getReserves(factory, path[i], path[i + 1]);
            amounts[i + 1] = getAmountOut(amounts[i], reserveIn, reserveOut);
        }
    }

    // performs chained getAmountIn calculations on any number of pairs
    function getAmountsIn(address factory, uint amountOut, address[] memory path) internal view returns (uint[] memory amounts) {
        require(path.length >= 2, 'PancakeLibrary: INVALID_PATH');
        amounts = new uint[](path.length);
        amounts[amounts.length - 1] = amountOut;
        for (uint i = path.length - 1; i > 0; i--) {
            (uint reserveIn, uint reserveOut) = getReserves(factory, path[i - 1], path[i]);
            amounts[i - 1] = getAmountIn(amounts[i], reserveIn, reserveOut);
        }
    }
}

// helper methods for interacting with ERC20 tokens and sending ETH that do not consistently return true/false
library TransferHelper {
    function safeApprove(address token, address to, uint value) internal {
        // bytes4(keccak256(bytes('approve(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: APPROVE_FAILED');
    }

    function safeTransfer(address token, address to, uint value) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FAILED');
    }

    function safeTransferFrom(address token, address from, address to, uint value) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FROM_FAILED');
    }

    function safeTransferETH(address to, uint value) internal {
        (bool success,) = to.call{value:value}(new bytes(0));
        require(success, 'TransferHelper: ETH_TRANSFER_FAILED');
    }
}

interface IBog {
    function distribute(uint256 amount) external;
}

interface IWBNB {
    function deposit() external payable;
    function transfer(address to, uint value) external returns (bool);
    function withdraw(uint) external;
}

/**
 * PancakeswapFactory
 */
interface IPancakeFactory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    function feeTo() external view returns (address);
    function feeToSetter() external view returns (address);

    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);

    function createPair(address tokenA, address tokenB) external returns (address pair);

    function setFeeTo(address) external;
    function setFeeToSetter(address) external;
}

/**
 * PancakeswapPair
 */
interface IPancakePair {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external pure returns (string memory);
    function symbol() external pure returns (string memory);
    function decimals() external pure returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function PERMIT_TYPEHASH() external pure returns (bytes32);
    function nonces(address owner) external view returns (uint);

    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;

    event Mint(address indexed sender, uint amount0, uint amount1);
    event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
    event Swap(
        address indexed sender,
        uint amount0In,
        uint amount1In,
        uint amount0Out,
        uint amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint);
    function factory() external view returns (address);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function price0CumulativeLast() external view returns (uint);
    function price1CumulativeLast() external view returns (uint);
    function kLast() external view returns (uint);

    function mint(address to) external returns (uint liquidity);
    function burn(address to) external returns (uint amount0, uint amount1);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function skim(address to) external;
    function sync() external;

    function initialize(address, address) external;
}

/**
 * PancakeswapRouter
 */
interface IPancakeRouter01 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);
    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountToken, uint amountETH);
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);

    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}

interface IPancakeRouter02 is IPancakeRouter01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountETH);
    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}

/**
 * Provides ownable & authorized contexts 
 */
abstract contract BogAuth {
    address payable _owner;
    mapping (address => bool) _authorizations;
    
    constructor() { 
        _owner = msg.sender; 
        _authorizations[msg.sender] = true;
    }
    
    /**
     * Check if address is owner
     */
    function isOwner(address account) public view returns (bool) {
        return account == _owner;
    }
    
    /**
     * Function modifier to require caller to be contract owner
     */
    modifier owned() {
        require(isOwner(msg.sender)); _;
    }
    
    /**
     * Function modifier to require caller to be authorized
     */
    modifier authorized() {
        require(_authorizations[msg.sender] == true); _;
    }
    
    /**
     * Authorize address. Any authorized address
     */
    function authorize(address adr) public authorized {
        _authorizations[adr] = true;
    }
    
    /**
     * Remove address' authorization. Owner only
     */
    function unauthorize(address adr) public authorized {
        require(adr != _owner);
        _authorizations[adr] = false;
    }
    
    /**
     * Transfer ownership to new address. Caller must be owner.
     */
    function transferOwnership(address payable adr) public owned {
        _owner = adr;
        _authorizations[adr] = true;
    }
}

interface IBogLimitOrdersV1 {
    enum OrderStatus { PENDING, FILLED, CANCELLED }
    enum OrderType { BNB_TOKEN, TOKEN_TOKEN, TOKEN_BNB }
    
    function getRouterAddress() external view returns (address);
    
    function placeBNBTokenOrder(address tokenOut, uint256 targetAmountOut, uint256 minAmountOut) external payable;
    function placeTokenTokenOrder(address tokenIn, uint256 amountIn, address tokenOut, uint256 targetAmountOut, uint256 minAmountOut) external;
    function placeTokenBNBOrder(address tokenIn, uint256 amountIn, uint256 targetAmountOut, uint256 minAmountOut) external;
    
    function cancelOrder(uint256 orderID) external;
    
    function canFulfilOrder(uint256 orderID) external view returns (bool);
    function shouldFulfilOrder(uint256 orderID) external view returns (bool);
    
    function fulfilOrder(uint256 orderID) external returns (bool filled);
    function fulfilMany(uint256[] calldata orderIDs) external;
    
    function getPendingOrders() external view returns (uint256[] memory);
    function getNextReadyOrder() external view returns (uint256);
    
    function getOrdersForAddress(address adr) external view returns (uint256[] memory);
    function getOrdersForPair(address pair) external view returns (uint256[] memory);
    function getOrdersForPair(address tokenIn, address tokenOut) external view returns (uint256[] memory);
    
    event OrderPlaced(uint256 orderID, address owner, uint256 amountIn, address tokenIn, address tokenOut, uint256 targetAmountOut, uint256 minAmountOut);
    event OrderCancelled(uint256 orderID);
    event OrderFulfilled(uint256 orderID, address broker);
}

/**
 * Use second contract for router as allows try catch on external router calls from main contract to make cancelling failing swaps possible in same tx
 */
contract BogOrderRouter {
    using SafeMath for uint256;
    
    enum OrderStatus { PENDING, FILLED, CANCELLED }
    enum OrderType { BNB_TOKEN, TOKEN_TOKEN, TOKEN_BNB }
    
    struct Order {
        uint256 id;                 // Order ID 
        uint256 pendingIndex;       // Index in pending order array
        address owner;              // Order placer 
        OrderStatus status;         // Order status 
        OrderType swapType;         // Order type
        address tokenIn;            // Token to swap 
        address tokenOut;           // Token to swap for
        address pair;               // PancakeswapPair
        uint256 amountIn;           // BNB Amount in 
        uint256 targetAmountOut;    // Price to trigger order at 
        uint256 minAmountOut;       // Max price to trigger order at (in case price changed before tx has been mined)
        uint256 timestamp;
        uint256 feePaid;
    }
    
    address public constant WBNB = 0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c;
    
    address authorizedCaller;
    
    constructor () {
        authorizedCaller = msg.sender;
    }
    
    modifier onlyAuthorized() {
        require(msg.sender == authorizedCaller); _;
    }
    
    receive() external payable {
        assert(msg.sender == WBNB);
    }
    
    function makeTokenTokenSwap(address owner, address tokenIn, address tokenOut, address pair, uint256 amountIn, uint256 minAmountOut) external onlyAuthorized {
        TransferHelper.safeTransferFrom(
            tokenIn, owner, pair, amountIn
        );
        
        uint balanceBefore = IBEP20(tokenOut).balanceOf(owner);
        _swap(pair, tokenIn, tokenOut, owner);
        
        require(
            IBEP20(tokenOut).balanceOf(owner).sub(balanceBefore) >= minAmountOut,
            'BogRouter: INSUFFICIENT_OUTPUT_AMOUNT'
        );
    }
    
    function makeBNBTokenSwap(address owner, address tokenIn, address tokenOut, address pair, uint256 amountIn, uint256 minAmountOut) external payable onlyAuthorized {
        // Swap bnb for wbnb then transfer to pair
        IWBNB(WBNB).deposit{value: amountIn}();
        assert(IWBNB(WBNB).transfer(pair, amountIn));
        
        uint balanceBefore = IBEP20(tokenOut).balanceOf(owner);
        _swap(pair, tokenIn, tokenOut, owner);
        
        require(
            IBEP20(tokenOut).balanceOf(owner).sub(balanceBefore) >= minAmountOut,
            'BogRouter: INSUFFICIENT_OUTPUT_AMOUNT'
        );
    }
    
    function makeTokenBNBSwap(address owner, address tokenIn, address tokenOut, address pair, uint256 amountIn, uint256 minAmountOut) external onlyAuthorized {
        TransferHelper.safeTransferFrom(
            tokenIn, owner, pair, amountIn
        );
        
        uint balanceBefore = IBEP20(WBNB).balanceOf(address(this));
        _swap(pair, tokenIn, tokenOut, address(this));
        
        uint amountOut = IBEP20(WBNB).balanceOf(address(this)).sub(balanceBefore);
        
        require(amountOut >= minAmountOut, 'BogRouter: INSUFFICIENT_OUTPUT_AMOUNT');
        
        IWBNB(WBNB).withdraw(amountOut);
        
        TransferHelper.safeTransferETH(owner, amountOut);
    }
    
    function _swap(address _pair, address tokenIn, address tokenOut, address to) internal virtual {
        (address token0,) = PancakeLibrary.sortTokens(tokenIn, tokenOut);
        IPancakePair pair = IPancakePair(_pair);
        
        uint amountInput;
        uint amountOutput;
        
        { // scope to avoid stack too deep errors
        (uint reserve0, uint reserve1,) = pair.getReserves();
        (uint reserveInput, uint reserveOutput) = tokenIn == token0 ? (reserve0, reserve1) : (reserve1, reserve0);
        amountInput = IBEP20(tokenIn).balanceOf(address(pair)).sub(reserveInput);
        amountOutput = PancakeLibrary.getAmountOut(amountInput, reserveInput, reserveOutput);
        }
        
        (uint amount0Out, uint amount1Out) = tokenIn == token0 ? (uint(0), amountOutput) : (amountOutput, uint(0));
        pair.swap(amount0Out, amount1Out, to, new bytes(0));
    }
}

/**
 * 
 */
contract BogLimitOrdersV1 is BogAuth, IBogLimitOrdersV1 {
    using SafeMath for uint256;
    
    struct Order {
        uint256 id;                 // Order ID 
        uint256 pendingIndex;       // Index in pending order array
        address owner;              // Order placer 
        OrderStatus status;         // Order status 
        OrderType swapType;         // Order type
        address tokenIn;            // Token to swap 
        address tokenOut;           // Token to swap for
        address pair;               // PancakeswapPair
        uint256 amountIn;           // BNB Amount in 
        uint256 targetAmountOut;    // Price to trigger order at 
        uint256 minAmountOut;       // Max price to trigger order at (in case price changed before tx has been mined)
        uint256 timestamp;          // Timestamp of last action (placed / filled / cancelled / etc)
        uint256 feePaid;
    }
    
    IPancakeRouter02 public constant router = IPancakeRouter02(0x05fF2B0DB69458A0750badebc4f9e13aDd608C7F);
    address public constant WBNB = 0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c;
    address constant BUSD = 0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56;
    address constant WBNB_BUSD = 0x1B96B92314C44b159149f7E0303511fB2Fc4774f;
    address constant BOG = address(0xD7B729ef857Aa773f47D37088A1181bB3fbF0099);
    
    uint256 public constant UINT_MAX = uint256(-1);
    
    uint256 public constant PRICE_DECIMALS = 10;
    
    address public factory;
    uint256 public constant ORDER_EXPIRY = 7 days;
    uint256 public nextOrder = 1;
    uint256 public fee = 250; // $2.50
    uint256 public feeSplit = 50; // 50% to stakers
    uint256 public totalFees;
    uint256 public totalDistributed;
    
    // token blacklisting
    mapping (address => bool) public blacklisted;
    mapping (address => bool) public whitelisted;
    bool useWhitelist;
    
    // orders
    mapping (uint256 => Order) public orders;
    mapping (address => uint256[]) public addressOrders;
    mapping (address => uint256[]) public pairOrders;
    uint256[] pendingOrders;
    
    BogOrderRouter bogRouter;
    
    constructor () {
        factory = router.factory();
        bogRouter = new BogOrderRouter();
    }
    
    bool entered = false;
    
    modifier reentrancyGuard() {
        require(!entered, "Reentrancy Disallowed");
        entered = true;
        _;
        entered = false;
    }
    
    function getRouterAddress() external view override returns (address) {
        return address(bogRouter);
    }
    
    function placeBNBTokenOrder(address tokenOut, uint256 targetAmountOut, uint256 minAmountOut) external payable override {
        createOrder(msg.sender, OrderType.BNB_TOKEN, WBNB, tokenOut, msg.value, targetAmountOut, minAmountOut, takeFee());
    }
    
    function placeBNBTokenOrderFor(address owner, address tokenOut, uint256 targetAmountOut, uint256 minAmountOut) external payable {
        createOrder(owner, OrderType.BNB_TOKEN, WBNB, tokenOut, msg.value, targetAmountOut, minAmountOut, takeFee());
    }
    
    function placeTokenTokenOrder(address tokenIn, uint256 amountIn, address tokenOut, uint256 targetAmountOut, uint256 minAmountOut) external override {
        require(IBEP20(tokenIn).allowance(msg.sender, address(bogRouter)) >= amountIn, "Not enough allowance for order");
        
        createOrder(msg.sender, OrderType.BNB_TOKEN, WBNB, tokenOut, amountIn, targetAmountOut, minAmountOut, takeFee());
    }
    
    function placeTokenBNBOrder(address tokenIn, uint256 amountIn, uint256 targetAmountOut, uint256 minAmountOut) external override {
        require(IBEP20(tokenIn).allowance(msg.sender, address(bogRouter)) >= amountIn, "Not enough allowance for order");
        
        createOrder(msg.sender, OrderType.TOKEN_BNB, tokenIn, WBNB, amountIn, targetAmountOut, minAmountOut, takeFee());
    }
    
    function createOrder(
        address owner,
        OrderType swapType,
        address tokenIn,
        address tokenOut,
        uint256 amountIn, 
        uint256 targetAmountOut, 
        uint256 minAmountOut, 
        uint256 feePaid
    )
        internal 
        returns (uint256) 
    {
        address pair = IPancakeFactory(factory).getPair(tokenIn, tokenOut);
        require(pair != address(0), "Pancakeswap pair does not exist");
        
        require(minAmountOut <= targetAmountOut, "Invalid output amounts");
        
        require(!blacklisted[tokenIn] && !blacklisted[tokenOut], "Token blacklisted");
        if(useWhitelist){
            require(whitelisted[tokenIn] && whitelisted[tokenOut], "Token not whitelisted");
        }
        
        uint256 orderID = nextOrder++;
        
        uint256 pendingIndex = pendingOrders.length;
        pendingOrders.push(orderID);
        
        addressOrders[msg.sender].push(orderID);
        pairOrders[pair].push(orderID);
        
        orders[orderID] = Order(
            orderID,
            pendingIndex,
            owner,
            OrderStatus.PENDING,
            swapType,
            tokenIn,
            tokenOut,
            pair,
            amountIn,
            targetAmountOut,
            minAmountOut,
            block.timestamp,
            feePaid
        );
        
        emit OrderPlaced(orderID, msg.sender, amountIn, tokenIn, tokenOut, targetAmountOut, minAmountOut);
        return orderID;
    }
    
    function cancelOrder(uint256 orderID) external override {
        Order memory ord = orders[orderID]; // gas saving
        
        // require caller to be authorized & order be pending
        require(msg.sender == ord.owner || ord.timestamp + ORDER_EXPIRY >= block.timestamp || _authorizations[msg.sender] == true, "You are not authorized to cancel this order.");
        require(ord.status == OrderStatus.PENDING, "Order must be a pending order");
        
        _cancelOrder(orderID);
    }
    
    function _cancelOrder(uint256 orderID) internal {
        Order memory ord = orders[orderID]; // gas saving
        
        // refund and close
        if(ord.swapType == OrderType.BNB_TOKEN){
            payable(ord.owner).transfer(ord.amountIn);
        }
        closeOrder(orderID, OrderStatus.CANCELLED);
        
        emit OrderCancelled(orderID);
    }
    
    function fulfilOrder(uint256 orderID) public override reentrancyGuard returns (bool filled) {
        Order memory ord = orders[orderID]; // saves gas
        
        require(ord.status == OrderStatus.PENDING, "Can't fulfil non-pending order");
        
        if(makeSwap(ord)){
            closeOrder(orderID, OrderStatus.FILLED);
            
            emit OrderFulfilled(orderID, msg.sender);
            return true;
        }else{
            // If order can be filled but wasn't then cancel order as there must be issue with token / slippage / etc
            // If unable to fulfil due to balance / allowance then also cancel
            if(canFulfilOrder(orderID) || unableToFulfil(orderID)){
                _cancelOrder(orderID);
                emit OrderCancelled(orderID);
            }
            
            return false;   
        }
    }
    
    function fulfilMany(uint256[] calldata orderIDs) external override {
        for(uint256 i = 0; i < orderIDs.length; i++){
            fulfilOrder(orderIDs[i]);
        }
    }
    
    function closeOrder(uint256 orderID, OrderStatus status) internal {
        // Remove order from pending by swapping in last pending order then pop from array
        pendingOrders[orders[orderID].pendingIndex] = pendingOrders[pendingOrders.length - 1];
        
        // change pending index for moved order
        orders[pendingOrders[orders[orderID].pendingIndex]].pendingIndex = orders[orderID].pendingIndex;
        
        // pop duplicate pending order from end
        pendingOrders.pop();
        
        // close with status
        orders[orderID].status = status;
        orders[orderID].timestamp = block.timestamp; // update last action timestamp
    }
    
    function canFulfilOrder(uint256 orderID) public view override returns (bool) {
        Order memory ord = orders[orderID];
        return ord.status == OrderStatus.PENDING && getCurrentAmountOut(orderID) >= ord.minAmountOut;
    }
    
    function unableToFulfil(uint256 orderID) internal view returns (bool) {
        Order memory ord = orders[orderID];
        return IBEP20(ord.tokenIn).balanceOf(ord.owner) < ord.amountIn || IBEP20(ord.tokenIn).allowance(ord.owner, address(bogRouter)) < ord.amountIn;
    }
    
    function shouldFulfilOrder(uint256 orderID) public view override returns (bool) {
        Order memory ord = orders[orderID];
        return ord.status == OrderStatus.PENDING && getCurrentAmountOut(orderID) >= ord.targetAmountOut;
    }
    
    function getCurrentAmountOut(uint256 orderID) public view returns (uint256 amount) {
        Order memory ord = orders[orderID]; // save gas
        
        (uint reserveIn, uint reserveOut) = getReserves(ord.pair, ord.tokenIn, ord.tokenOut);
        return getAmountOut(ord.amountIn, reserveIn, reserveOut);
    }
    
    // returns sorted token addresses, used to handle return values from pairs sorted in this order
    function sortTokens(address tokenA, address tokenB) public pure returns (address token0, address token1) {
        (token0, token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
    }

    // fetches and sorts the reserves for a pair
    function getReserves(address pair, address tokenA, address tokenB) public view returns (uint reserveA, uint reserveB) {
        (address token0,) = sortTokens(tokenA, tokenB);
        (uint reserve0, uint reserve1,) = IPancakePair(pair).getReserves();
        (reserveA, reserveB) = tokenA == token0 ? (reserve0, reserve1) : (reserve1, reserve0);
    }
    
    // given an input amount of an asset and pair reserves, returns the maximum output amount of the other asset
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) public pure returns (uint amountOut) {
        uint amountInWithFee = amountIn.mul(998);
        uint numerator = amountInWithFee.mul(reserveOut);
        uint denominator = reserveIn.mul(1000).add(amountInWithFee);
        amountOut = numerator / denominator;
    }
    
    function makeSwap(Order memory ord) internal returns (bool filled) {
        if(ord.swapType == OrderType.BNB_TOKEN){
            try bogRouter.makeBNBTokenSwap{value: ord.amountIn}(ord.owner, ord.tokenIn, ord.tokenOut, ord.pair, ord.amountIn, ord.minAmountOut) { return true; } catch { return false; }
        }else if(ord.swapType == OrderType.TOKEN_TOKEN){
            try bogRouter.makeTokenTokenSwap(ord.owner, ord.tokenIn, ord.tokenOut, ord.pair, ord.amountIn, ord.minAmountOut) { return true; } catch { return false; }
        }else{ // OrderType.TOKEN_BNB
            try bogRouter.makeTokenBNBSwap(ord.owner, ord.tokenIn, ord.tokenOut, ord.pair, ord.amountIn, ord.minAmountOut) { return true; } catch { return false; }
        }
    }
    
    /**
     * Distribute fees to staker and owner.
     */
    function distributeFees() external {
        uint256 toDistribute = IBEP20(BOG).balanceOf(address(this)).mul(feeSplit).div(100);
        totalDistributed = totalDistributed.add(toDistribute);
        
        // Distribute to stakers & send to authorized fee taker
        IBog(BOG).distribute(toDistribute);
        IBEP20(BOG).transfer(_owner, IBEP20(BOG).balanceOf(address(this)));
    }
    
    function getFeeInBOG() public view returns (uint256) {
        uint256 bog_bnb = getTokenTokenPrice(WBNB, BOG);
        uint256 bnb_usd = getTokenTokenPrice(BUSD, WBNB);
        
        uint256 bnbAmt = bnb_usd.mul(fee);
        uint256 bogAmt = bnbAmt.mul(bog_bnb).div(10 ** PRICE_DECIMALS).mul(10 ** 18).div(10 ** PRICE_DECIMALS).div(100);
        
        return bogAmt;
    }
    
    function takeFee() internal returns (uint256 amount) {
        if(_authorizations[msg.sender]){ return 0; }
        
        if(msg.sender == tx.origin){
            // Take fee
            amount = getFeeInBOG();
        }else{
            // Take 0.25 BOG fee as fiat price could be manipulated
            amount = 250 * (10 ** 16);
        }
        
        IBEP20(BOG).transferFrom(msg.sender, address(this), amount);
        totalFees = totalFees.add(amount);
    }
    
    function getPendingOrders() external view override returns (uint256[] memory) {
        return pendingOrders;
    }
    
    function getNextReadyOrder() external view override returns (uint256 orderID) {
        for(uint256 i = 0; i < pendingOrders.length; i++){
            if(canFulfilOrder(i)){
                return i;
            }
        }
        return 0;
    }
    
    function getOrdersForAddress(address adr) external view override returns (uint256[] memory) {
        return addressOrders[adr];
    }
    
    function getOrdersForPair(address pair) external view override returns (uint256[] memory) {
        return pairOrders[pair];
    }
    
    function getOrdersForPair(address tokenIn, address tokenOut) external view override returns (uint256[] memory) {
        return pairOrders[getPair(tokenIn, tokenOut)];
    }
    
    function getPair(address tokenIn, address tokenOut) public view returns (address) {
        return IPancakeFactory(factory).getPair(tokenIn, tokenOut);
    }
    
    /**
     * Returns 10^decimals * tokenOut per tokenIn
     */
    function getTokenTokenPrice(address tokenIn, address tokenOut) public view returns (uint256) {
        address pair = getPair(tokenIn, tokenOut);
        
        (uint112 reserve0, uint112 reserve1,) = IPancakePair(pair).getReserves();
        
        (uint256 quoteToken, uint256 mainToken) = IPancakePair(pair).token0() == tokenOut ? (reserve0, reserve1) : (reserve1, reserve0);
        
        return calculatePriceFromReserves(quoteToken, mainToken);
    }
    
    function symbolFor(address token) external view returns (string memory) {
        return IBEP20(token).symbol();
    }
    
    /**
     * USD per BNB
     */
    function getBNBSpotPrice() external view returns (uint256) {
        // res0 = wbnb, res1 = busd
        (uint112 reserve0, uint112 reserve1,) = IPancakePair(WBNB_BUSD).getReserves();
        
        return calculatePriceFromReserves(reserve1, reserve0);
    }
    
    /**
     * Returns 10^decimals * quoteToken per baseToken
     */
    function calculatePriceFromReserves(uint256 quoteToken, uint256 baseToken) internal pure returns (uint256) {
        return quoteToken.mul(10 ** PRICE_DECIMALS).div(baseToken);
    }
    
    function setBlacklist(address token, bool state) external authorized {
        blacklisted[token] = state;
    }
    
    function setWhitelist(address token, bool state) external authorized {
        whitelisted[token] = state;
    }
    
    function setWhitelistState(bool state) external authorized {
        useWhitelist = state;
    }
    
    function changeFeeSplit(uint256 newSplit) external authorized {
        require(newSplit > 0 && newSplit < 100);
        feeSplit = newSplit;
    }
    
    function changeFee(uint256 newFee) external authorized {
        require(newFee > 0 && newFee < 500);
        fee = newFee;
    }
}
