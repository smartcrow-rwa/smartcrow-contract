// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {FunctionsClient} from "@chainlink/contracts/src/v0.8/functions/v1_0_0/FunctionsClient.sol";
import {ConfirmedOwner} from "@chainlink/contracts/src/v0.8/shared/access/ConfirmedOwner.sol";
import {FunctionsRequest} from "@chainlink/contracts/src/v0.8/functions/v1_0_0/libraries/FunctionsRequest.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {PullPayment} from "./PullPayment.sol";
import {ReentrancyGuard} from "./ReentrancyGuard.sol";

/**
 * @title SenderFundsContract
 * @dev This contract uses hardcoded values and should not be used in production.
 */
abstract contract SenderFundsContract is PullPayment, ReentrancyGuard, FunctionsClient, ConfirmedOwner {
    using FunctionsRequest for FunctionsRequest.Request;

    // State variables to store the last request ID, response and error
    bytes32 public s_lastRequestId;
    bytes public s_lastResponse;
    uint256 public s_totalCarbonGas;
    bytes public s_lastError;


    address public s_sender;
    address public s_receiver;
    string public s_propertyNumber;
    uint256 public s_meetSalesCondition;
    uint256 public s_postDeadlineCheck;
    uint64 public subscriptionID = 75;


    error UnexpectedRequestID(bytes32 requestId);

        struct BonusInfo {
            address sender;
            address receiver;
            uint256 bonusAmount;
            uint256 startDate;
            uint256 sellByDate;
            uint256 atCondition;
            uint256 minRequestDays;
            uint256 atPrice;
            uint256 meetSalesCondition;
            uint256 postDeadlineCheck;
            uint256 fundsWithdrawn;
            address token; // Token address
        }


        using SafeERC20 for IERC20;
        IERC20 public immutable usdtToken;
        IERC20 public immutable usdcToken;
        IERC20 public immutable wbtcToken;
        IERC20 public immutable daiToken;
        IERC20 public immutable wethToken;
        
        uint256 private constant _IS_TRUE = 1;
        uint256 private constant _IS_FALSE = 2;
        // atCondition can be used as 1 => atOrAbove, 2=> atOrBelow 3=> Both false
        uint256 private constant _IS_NEUTRAL = 3;


        mapping(address => mapping(address => mapping(string => BonusInfo))) public bonusInfo;
        event BonusInfoCreated(address indexed sender, address indexed receiver, string indexed propertyNumber, uint256 bonusAmount, address token);
        event FundsWithdrawn(address indexed sender, address indexed receiver, string indexed propertyNumber, uint256 bonusAmount, address token);
        event BonusInfoUpdated(address indexed sender, address indexed receiver, string indexed propertyNumber, uint256 meetSalesCondition, uint256 postDeadlineCheck);



    event Response(bytes32 indexed requestId, bytes response, bytes err);
    event DecodedResponse(
        bytes32 indexed requestId,
        uint256 answer,
        uint256 updatedAt,
        uint8 decimals,
        string description
    );

    // // Router address - Hardcoded for Polygon Mainnet
    // address router = 0xdc2AAF042Aeff2E68B3e8E33F19e4B9fA7C73F10;

    address public constant router = 0x234a5fb5Bd614a7AA2FfAB244D603abFA0Ac5C5C;

        // Callback gas limit
    uint32 public constant gasLimit = 300_000;

    // // donID - Hardcoded for Polygon Mainnet
    // bytes32 public constant donID =
    //     0x66756e2d706f6c79676f6e2d6d61696e6e65742d310000000000000000000000;

    // donID - Arbitrum Sepolia
    bytes32 public constant donID = 0x66756e2d617262697472756d2d7365706f6c69612d3100000000000000000000;


// Source JavaScript to run
    string public constant source =
    // Get arguments from contract
    "const sender1 = args[0];"
    "const receiver1 = args[1];"
    "const propertyNumber1 = args[2];"
    "const contractAddress1 = args[3];"
    // // // //
    "const {getABI} = await import(\"https://deno.land/x/smartcrow@v1.0.0/mod.ts\");"
    "const {checkSalesCondition} = await import(\"https://deno.land/x/smartcrow@v1.0.0/mod.ts\");"
    "const {extractAddressAndZip} = await import(\"https://deno.land/x/smartcrow@v1.0.0/mod.ts\");"

    // Contract ABI
    "const abi = getABI();"

        //Get Separated Address and Zip Code
    "const { formattedAddress, postalCode, streetAddress } = extractAddressAndZip("
    "propertyNumber1,"
    ");"

        // Get property details


    "const response = await Functions.makeHttpRequest({"
    "  url: \"https://api.propmix.io/pubrec/assessor/v1/GetPropertyDetails\","
    "  method: \"GET\", "
    "  headers: {'Access-Token': secrets.apiKey },"
    "  params: {"
    "            OrderId: formattedAddress,"
    "            StreetAddress: streetAddress,"
    "            PostalCode: parseInt(postalCode),"
    "          }"
    "});"
    "if (response.error) {"
    "  throw Error(`Error fetching API`);"
    "};"
    "const theResponse = await response;"
    "const lastSaleDate = theResponse.data.Data.Listing.LastSaleRecordingDate;"
    "const lastSalePrice = theResponse.data.Data.Listing.LastSalePrice;"


    // Read BonusInfo
    "const ethers = await import(\"npm:ethers@6.10.0\");"

                "class FunctionsJsonRpcProvider extends ethers.JsonRpcProvider {"
                "  constructor(url) {"
                "    super(url);"
                "    this.url = url;"
                "  }"

                "  async _send(payload) {"
                "    let resp = await fetch(this.url, {"
                "      method: \"POST\","
                "      headers: { \"Content-Type\": \"application/json\" },"
                "      body: JSON.stringify(payload),"
                "    });"
                "    return resp.json();"
                "  }"
                "}"

    "const provider1 = new FunctionsJsonRpcProvider(secrets.rpcUrl);"

    "const contract1 = new ethers.Contract(contractAddress1, abi, provider1);"
    "const tx = await contract1.bonusInfo(sender1, receiver1, propertyNumber1);"

    // Check Sales condition
    // Store sales details from agreement
    // Declare variables for the condition
    // Check Deadline and Post Deadline Check
    "const { result, deadlineCheckResult } = await checkSalesCondition("
    "  tx,"
    "  lastSaleDate,"
    "  lastSalePrice,"
    ");"
    // Final conditions
    "const meetSalesCondition: number = result.condition === true ? 1 : 2;"
    "const postDeadlineCheck: number = deadlineCheckResult === true ? 1 : 2;"
        
    // Send Final Details to Contract
    "const encoded = ethers.AbiCoder.defaultAbiCoder().encode("
    "['address','address','string','uint256', 'uint256'],"
    "[args[0],args[1],args[2], meetSalesCondition, postDeadlineCheck]"
    ");"
    "return ethers.getBytes(encoded);"

    ;



    /**
     * @notice Initializes the contract with the Chainlink router address and sets the contract owner
     */
    constructor(
    address _usdtToken,
    address _usdcToken,
    address _wbtcToken,
    address _daiToken,
    address _wethToken
) {
    usdtToken = IERC20(_usdtToken);
    usdcToken = IERC20(_usdcToken);
    wbtcToken = IERC20(_wbtcToken);
    daiToken = IERC20(_daiToken);
    wethToken = IERC20(_wethToken);

    require(
        usdtToken.approve(address(this), type(uint256).max),
        "USDT approval failed"
    );
    require(
        usdcToken.approve(address(this), type(uint256).max),
        "USDC approval failed"
    );
    require(
        wbtcToken.approve(address(this), type(uint256).max),
        "WBTC approval failed"
    );
    require(
        daiToken.approve(address(this), type(uint256).max),
        "DAI approval failed"
    );
    require(
        wethToken.approve(address(this), type(uint256).max),
        "WETH approval failed"
    );
}
    function changeSubscriptionID(uint64 _subscriptionID) external onlyOwner {
        subscriptionID = _subscriptionID;
    }

function createBonusInfo(
    address receiver,
    string memory propertyNumber,
    uint256 startDateInUnixSeconds,
    uint256 sellByDateInUnixSeconds,
    uint256 atCondition,
    uint256 minRequestDays,
    uint256 atPrice,
    uint256 bonusAmount,
    address token
) external payable {
    // Perform all checks
    require(
        (token == address(usdtToken) || token == address(usdcToken) || token == address(wbtcToken) || token == address(daiToken) || token == address(wethToken)) || 
        (token == address(0) && msg.value == bonusAmount),
        "Unsupported token or insufficient native funds"
    );

    require(msg.sender != receiver, "You cannot be the receiver yourself");
    require(atCondition == _IS_FALSE || atCondition == _IS_TRUE || atCondition == _IS_NEUTRAL, "Invalid atCondition");
    require(minRequestDays == _IS_FALSE || minRequestDays == _IS_TRUE, "Invalid minRequestDays");
    require(sellByDateInUnixSeconds > startDateInUnixSeconds, "End date must be greater than start date");
    
    BonusInfo storage info = bonusInfo[msg.sender][receiver][propertyNumber];
    require(info.sender == address(0) || info.fundsWithdrawn == _IS_TRUE, "Either bonus info doesn't exist or funds must be withdrawn before creating a new BonusInfo");

    // Update state first
    setBonusInfo(
        msg.sender,
        receiver,
        propertyNumber,
        (token == address(0)) ? msg.value : bonusAmount,
        startDateInUnixSeconds,
        sellByDateInUnixSeconds,
        atCondition,
        minRequestDays,
        atPrice,
        token
    );

    // Perform external calls last
    if (token == address(0)) {
        // ETH transfer
        _asyncTransfer(msg.sender, receiver, propertyNumber, bonusAmount);
    } else {
        // Token transfer
        IERC20(token).safeTransferFrom(msg.sender, address(this), bonusAmount);
    }

    emit BonusInfoCreated(msg.sender, receiver, propertyNumber, bonusAmount, token);
}


function setBonusInfo(
    address sender,
    address receiver,
    string memory propertyNumber,
    uint256 bonusAmount,
    uint256 startDateInUnixSeconds,
    uint256 sellByDateInUnixSeconds,
    uint256 atCondition,
    uint256 minRequestDays,
    uint256 atPrice,
    address token
) internal {
    bonusInfo[sender][receiver][propertyNumber] = BonusInfo({
        sender: sender,
        receiver: receiver,
        bonusAmount: bonusAmount,
        startDate: startDateInUnixSeconds,
        sellByDate: sellByDateInUnixSeconds,
        atCondition: atCondition,
        minRequestDays: minRequestDays,
        atPrice: atPrice,
        meetSalesCondition: _IS_FALSE,
        postDeadlineCheck: _IS_FALSE,
        fundsWithdrawn: _IS_FALSE,
        token: token
    });
}

    function fulfillRequest(
        bytes32 requestId,
        bytes memory response,
        bytes memory err
    ) internal override {
        if (s_lastRequestId != requestId) {
            revert UnexpectedRequestID(requestId);
        }

        s_lastError = err;
        s_lastResponse = response;

        if (response.length > 0) {
            (
                address sender,
                address receiver,
                string memory propertyNumber,
                uint256 meetSalesCondition,
                uint256 postDeadlineCheck
            ) = abi.decode(response, (address, address, string, uint256, uint256));

           BonusInfo storage info = bonusInfo[sender][receiver][propertyNumber];
            require(info.sender != address(0), "No active bonus for this sender.");

            info.meetSalesCondition = meetSalesCondition;
            info.postDeadlineCheck = postDeadlineCheck;

            emit BonusInfoUpdated(sender, receiver, propertyNumber, meetSalesCondition, postDeadlineCheck);

        }

        emit Response(requestId, response, err);
    }

            function withdrawFundsSender(address Sender, address Receiver, string memory propertyNumber) external nonReentrant {
            BonusInfo storage info = bonusInfo[Sender][Receiver][propertyNumber];
            require(info.sender != address(0), "No active bonus for this sender.");
            require(info.fundsWithdrawn != _IS_TRUE, "The bonus has already been paid out.");
            require(info.postDeadlineCheck == _IS_TRUE, "Post deadline check not performed.");
            require(info.meetSalesCondition!= _IS_TRUE, "The sales conditions are met for Receiver.");

            info.fundsWithdrawn = _IS_TRUE;

            if (info.token == address(0)) {
                withdrawPayments(payable(info.sender), Sender, Receiver, propertyNumber);
            } else {
                IERC20(info.token).safeTransferFrom(address(this), info.sender, info.bonusAmount);
            }

            emit FundsWithdrawn(Sender, Receiver, propertyNumber, info.bonusAmount, info.token);
        }

        function withdrawFundsReceiver(address Sender, address Receiver, string memory propertyNumber) external nonReentrant {
            BonusInfo storage info = bonusInfo[Sender][Receiver][propertyNumber];
            require(info.receiver != address(0), "No active bonus for this sender.");
            require(info.fundsWithdrawn != _IS_TRUE, "The bonus has already been paid out.");
            require(info.meetSalesCondition == _IS_TRUE, "Sales condition isn't met");

            info.fundsWithdrawn = _IS_TRUE;

            if (info.token == address(0)) {
                withdrawPayments(payable(info.receiver), Sender, Receiver, propertyNumber);
            } else {
                IERC20(info.token).safeTransferFrom(address(this), info.receiver, info.bonusAmount);
            }

            emit FundsWithdrawn(Sender, Receiver, propertyNumber, info.bonusAmount, info.token);
        }

    receive() external payable {}
}