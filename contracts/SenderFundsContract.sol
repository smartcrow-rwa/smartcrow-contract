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
contract SenderFundsContract is PullPayment, ReentrancyGuard, FunctionsClient, ConfirmedOwner {
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

        uint256 private constant _IS_TRUE = 1;
        uint256 private constant _IS_FALSE = 2;
        // atCondition can be used as 1 => atOrAbove, 2=> atOrBelow 3=> Both false
        uint256 private constant _IS_NEUTRAL = 3;

        using SafeERC20 for IERC20;
        IERC20 public usdtToken;
        IERC20 public usdcToken;
        IERC20 public wbtcToken;
        IERC20 public daiToken;
        IERC20 public wethToken;


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

    // Router address - Hardcoded for Polygon Amoy
    address router = 0xC22a79eBA640940ABB6dF0f7982cc119578E11De;

// Source JavaScript to run
    string source =
    // Get arguments from contract
    "const sender1 = args[0];"
    "const receiver1 = args[1];"
    "const propertyNumber1 = args[2];"
    "const contractAddress1 = args[3];"
    // // // //

// Contract ABI
"const abi = ["
"    {"
"      \"inputs\": ["
"        {"
"          \"internalType\": \"address\","
"          \"name\": \"\","
"          \"type\": \"address\""
"        },"
"        {"
"          \"internalType\": \"address\","
"          \"name\": \"\","
"          \"type\": \"address\""
"        },"
"        {"
"          \"internalType\": \"string\","
"          \"name\": \"\","
"          \"type\": \"string\""
"        }"
"      ],"
"      \"name\": \"bonusInfo\","
"      \"outputs\": ["
"        {"
"          \"internalType\": \"address\","
"          \"name\": \"sender\","
"          \"type\": \"address\""
"        },"
"        {"
"          \"internalType\": \"address\","
"          \"name\": \"receiver\","
"          \"type\": \"address\""
"        },"
"        {"
"          \"internalType\": \"uint256\","
"          \"name\": \"bonusAmount\","
"          \"type\": \"uint256\""
"        },"
"        {"
"          \"internalType\": \"uint256\","
"          \"name\": \"startDate\","
"          \"type\": \"uint256\""
"        },"
"        {"
"          \"internalType\": \"uint256\","
"          \"name\": \"sellByDate\","
"          \"type\": \"uint256\""
"        },"
"        {"
"          \"internalType\": \"uint256\","
"          \"name\": \"atCondition\","
"          \"type\": \"uint256\""
"        },"
"        {"
"          \"internalType\": \"uint256\","
"          \"name\": \"minRequestDays\","
"          \"type\": \"uint256\""
"        },"
"        {"
"          \"internalType\": \"uint256\","
"          \"name\": \"atPrice\","
"          \"type\": \"uint256\""
"        },"
"        {"
"          \"internalType\": \"uint256\","
"          \"name\": \"meetSalesCondition\","
"          \"type\": \"uint256\""
"        },"
"        {"
"          \"internalType\": \"uint256\","
"          \"name\": \"postDeadlineCheck\","
"          \"type\": \"uint256\""
"        },"
"        {"
"          \"internalType\": \"uint256\","
"          \"name\": \"fundsWithdrawn\","
"          \"type\": \"uint256\""
"        },"
"        {"
"          \"internalType\": \"address\","
"          \"name\": \"token\","
"          \"type\": \"address\""
"        }"
"      ],"
"      \"stateMutability\": \"view\","
"      \"type\": \"function\""
"    }"
"  ];"



    //Get Separated Address and Zip Code
 "const parts1 = propertyNumber1.split(/[\\s,-]+/);"
"let streetAddress1 = parts1.slice(0, 3).join(' ');"
"let postalCode1: string | null = null;"
"for (let i = parts1.length - 1; i >= 0; i--) {"
"    if (/^\\d+$/.test(parts1[i])) {"
"        postalCode1 = parts1[i];"
"        break;"
"    }"
"}"
"if (postalCode1 !== null) {"
"    streetAddress1 = streetAddress1.replace(/\\bStreet\\b/, 'St');"
"}"
"const addressInfo1 = { streetAddress: streetAddress1, postalCode: postalCode1 };"
"const addressParts1 = addressInfo1.streetAddress.split(' ');"
"const street1 = addressParts1.slice(1).join(' ').toUpperCase();"
"const city1 = addressParts1[addressParts1.length - 1];"
"const state1 = addressParts1[addressParts1.length - 2];"
"const formattedAddress1 = addressParts1[0] + \" \" + street1 + ', ' + city1 + ', ' + state1 + \" \" + addressInfo1.postalCode;"


    // Get property details


"const response = await Functions.makeHttpRequest({"
"  url: \"https://api.propmix.io/pubrec/assessor/v1/GetPropertyDetails\","
"  method: \"GET\", "
"  headers: {'Access-Token': secrets.apiKey },"
"  params: {"
"            OrderId: formattedAddress1,"
"            StreetAddress: addressInfo1.streetAddress,"
"            PostalCode: parseInt(addressInfo1.postalCode),"
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

"const provider1 = new FunctionsJsonRpcProvider(\"https://polygon-amoy.g.alchemy.com/v2/<YOUR_API_KEY_HERE>\");"

"const contract1 = new ethers.Contract(contractAddress1, abi, provider1);"
"const tx = await contract1.bonusInfo(sender1, receiver1, propertyNumber1);"

// Check Sales condition
// Store sales details from agreement
// Declare variables for the condition
"const stringArray = tx;"
"const atPrice: number = parseInt(stringArray[7], 10);"
"const startDate: number = parseInt(stringArray[3]);"
"const endDate: number = parseInt(stringArray[4]);"
// ## minRequestDays should be from stringArray
"const minRequestDays: number = parseInt(stringArray[6]);"
"const additionalDays = minRequestDays === 1 ? 2592000 : 5184000;"

// Unix Time Conversion
"const {DateTime} = await import(\"npm:luxon@3.4.4\");"
"const endingPeriod = await DateTime.fromSeconds(endDate).toFormat('yyyy-MM-dd HH:mm:ss');"
"const lockdownPeriod = await DateTime.fromSeconds(endDate + additionalDays).toFormat('yyyy-MM-dd HH:mm:ss');"

"const result = { condition: false, reason: '' };"

// Check Sales Condition - decision tree
"if (lastSaleDate && lastSalePrice) {"
  "const dateObject = new Date(lastSaleDate);"
  "const timestamp = Math.floor(dateObject.getTime() / 1000);"
  "console.log('start date, timestamp(last sale date), end date', startDate, timestamp, endDate);"

  "if (startDate < timestamp && timestamp <= endDate) {"
    "const atCondition = parseInt(stringArray[5]);"

    "if (atCondition === 1) {"
      "console.log('Last sales price, Expected sales price', lastSalePrice, atPrice);"
      "if (parseInt(lastSalePrice) >= atPrice) {"
        "result.condition = true;"
        "result.reason = 'Meets sales price, deadline and all criteria';"
      "} else {"
        "result.condition = false;"
        "result.reason = `Doesn't meet sales price, should be at or above. Lockout Period until: ${lockdownPeriod}`;"
      "}"
    "} else if (atCondition === 2) {"
      "console.log('Last sales price, Expected sales price', lastSalePrice, atPrice);"
      "if (parseInt(lastSalePrice) <= atPrice) {"
        "result.condition = true;"
        "result.reason = 'Meets sales price, deadline and all criteria';"
      "} else {"
        "result.condition = false;"
        "result.reason = `Doesn't meet sales price, should be at or below. Lockout Period until: ${lockdownPeriod}`;"
      "}"
    "} else {"
      "result.condition = true;"
      "result.reason = 'Meets condition without expected sales price';"
    "}"
  "} else {"
    "result.condition = false;"
    "result.reason = `Didn't perform sales within timeframe: ${endingPeriod}. Lockout Period until: ${lockdownPeriod}`;"
  "}"
"} else {"
  "result.condition = false;"
  "result.reason = `No latest sales data available. Lockout Period until: ${lockdownPeriod}`;"
"}"

// Check Deadline and Post Deadline Check
"const currentDateUnixTimeInSeconds = Math.floor(Date.now() / 1000);"
"const deadlineCheckResult: boolean = currentDateUnixTimeInSeconds > (endDate + additionalDays);"

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


    // Callback gas limit
    uint32 gasLimit = 300_000;

    // donID - Hardcoded for Polygon Amoy
    bytes32 donID =
        0x66756e2d706f6c79676f6e2d616d6f792d310000000000000000000000000000;

    /**
     * @notice Initializes the contract with the Chainlink router address and sets the contract owner
     */
    constructor(
            address _usdtToken,
            address _usdcToken,
            address _wbtcToken,
            address _daiToken,
            address _wethToken
    ) FunctionsClient(router) ConfirmedOwner(msg.sender) {
            usdtToken = IERC20(_usdtToken);
            usdcToken = IERC20(_usdcToken);
            wbtcToken = IERC20(_wbtcToken);
            daiToken = IERC20(_daiToken);
            wethToken = IERC20(_wethToken);
            usdtToken.approve(address(this), type(uint256).max);
            usdcToken.approve(address(this), type(uint256).max);
            wbtcToken.approve(address(this), type(uint256).max);
            daiToken.approve(address(this), type(uint256).max);
            wethToken.approve(address(this), type(uint256).max);
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
            require(
                (token == address(usdtToken) || token == address(usdcToken) || token == address(wbtcToken)  || token == address(daiToken) || token == address(wethToken)) || 
                (token == address(0) && msg.value == bonusAmount && msg.value >=0),
                "Unsupported token or insufficient native funds"
            );
            require(msg.sender != receiver, "You cannot be the receiver yourself");
            require(atCondition==_IS_FALSE || atCondition==_IS_TRUE || atCondition==_IS_NEUTRAL, "atCondition can be used as 1 => atOrAbove, 2=> atOrBelow 3=> Both false");
            require(minRequestDays==_IS_FALSE || minRequestDays==_IS_TRUE , "Minimum request Date can be 1 for 30 days and 2 for 60 days");
            require(sellByDateInUnixSeconds > startDateInUnixSeconds, "End date must be greater than start date");
            BonusInfo storage info = bonusInfo[msg.sender][receiver][propertyNumber];
            require(info.sender == address(0) || info.fundsWithdrawn == _IS_TRUE , "Either bonus info doesn't exist or Funds must be withdrawn before creating a new BonusInfo");

            if (token == address(0)){
                _asyncTransfer(msg.sender,receiver,propertyNumber, bonusAmount);
            } else
            {
            IERC20(token).safeTransferFrom(msg.sender, address(this), bonusAmount);
            }

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

            emit BonusInfoCreated(msg.sender, receiver, propertyNumber, bonusAmount, token);
        }


    function sendRequest(
        uint64 subscriptionId,
        bytes memory encryptedSecretsUrls,
        string[] memory args    
        )
        external
        onlyOwner
        returns (bytes32 requestId)
    {
        FunctionsRequest.Request memory req;
        req.initializeRequestForInlineJavaScript(source); // Initialize the request with JS code
        if (encryptedSecretsUrls.length > 0)
            req.addSecretsReference(encryptedSecretsUrls);
        // Send the request and store the request ID
        if (args.length > 0) req.setArgs(args);
        s_lastRequestId = _sendRequest(
            req.encodeCBOR(),
            subscriptionId,
            gasLimit,
            donID
        );

        return s_lastRequestId;
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