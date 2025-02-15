// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

import {VRFConsumerBaseV2Plus} from "@chainlink/contracts/src/v0.8/vrf/dev/VRFConsumerBaseV2Plus.sol";
import {VRFV2PlusClient} from "@chainlink/contracts/src/v0.8/vrf/dev/libraries/VRFV2PlusClient.sol";

contract CheckIn is VRFConsumerBaseV2Plus {
    using ECDSA for bytes32;

    address public signer;
    mapping(address => bool) public checkedIn;
    uint256 public startTime;
    uint256 public endTime;
    uint256 public nonce;

    address[] public participants;
    mapping(address => uint16) public participantsIndex;
    // number of winner
    uint256 public numOfWinners;

    event CheckInEvent(
        address indexed user,
        string message,
        uint256 indexed timestamp
    );

    // chainlink
    event RequestSent(uint256 requestId, uint32 numWords);
    event RequestFulfilled(uint256 requestId, uint256[] randomWords);

    struct RequestStatus {
        bool fulfilled; // whether the request has been successfully fulfilled
        bool exists; // whether a requestId exists
        uint256[] randomWords;
        uint16 selectedStartIndex;
        uint16 selectedEndIndex;
    }
    mapping(uint256 => RequestStatus)
        public s_requests; /* requestId --> requestStatus */

    // Your subscription ID.
    uint256 public s_subscriptionId;

    // Past request IDs.
    uint256[] public requestIds;
    uint256 public lastRequestId;

    bytes32 public keyHash =
        0x8596b430971ac45bdf6088665b9ad8e8630c9d5049ab54b14dff711bee7c0e26;

    // Depends on the number of requested values that you want sent to the
    // fulfillRandomWords() function. Storing each word costs about 20,000 gas,
    // so 100,000 is a safe default for this example contract. Test and adjust
    // this limit based on the network that you select, the size of the request,
    // and the processing of the callback request in the fulfillRandomWords()
    // function.
    uint32 callbackGasLimit = 100000;

    uint16 public requestConfirmations = 3;

    // For this example, retrieve 2 random values in one request.
    // Cannot exceed VRFCoordinatorV2_5.MAX_NUM_WORDS.
    uint32 public numWords = 1;

    constructor(
        address _signer,
        uint256 _startTime,
        uint256 _endTime,
        uint256 _subscriptionId,
        uint256 _numWinnder,
        bytes32 _keyHash,
        address _vrfCoordinator
    ) VRFConsumerBaseV2Plus(_vrfCoordinator) {
        require(_startTime < _endTime, "Start time must be before end time");
        startTime = _startTime;
        endTime = _endTime;
        signer = _signer;
        s_subscriptionId = _subscriptionId;
        numOfWinners = _numWinnder;
        keyHash = _keyHash;
    }

    function checkIn(
        string memory _message,
        uint8 _v,
        bytes32 _r,
        bytes32 _s
    ) public {
        require(block.timestamp >= startTime, "Check-in has not started yet");
        require(block.timestamp <= endTime, "Check-in has ended");
        require(!checkedIn[msg.sender], "Already checked in");
        //Recover the address from the signature
        address recoveredAddress = _verifyMessage(
            msg.sender,
            _message,
            nonce,
            _v,
            _r,
            _s
        );

        require(recoveredAddress == signer, "Invalid signature.");

        checkedIn[msg.sender] = true;
        participants.push(msg.sender);
        participantsIndex[msg.sender] = uint16(participants.length - 1);
        nonce++;
        emit CheckInEvent(msg.sender, _message, block.timestamp);
    }

    function setCheckInTimes(
        uint256 _startTime,
        uint256 _endTime
    ) public onlyOwner {
        require(_startTime < _endTime, "Start time must be before end time");
        startTime = _startTime;
        endTime = _endTime;
    }

    function setNumOfWinners(uint256 _numOfWinners) external onlyOwner {
        numOfWinners = _numOfWinners;
    }

    function setSigner(address _signer) external onlyOwner {
        signer = _signer;
    }

    // Assumes the subscription is funded sufficiently.
    // @param enableNativePayment: Set to `true` to enable payment in native tokens, or
    // `false` to pay in LINK
    function requestRandomWords(
        bool enableNativePayment
    ) external onlyOwner returns (uint256 requestId) {
        // Will revert if subscription is not set and funded.
        requestId = s_vrfCoordinator.requestRandomWords(
            VRFV2PlusClient.RandomWordsRequest({
                keyHash: keyHash,
                subId: s_subscriptionId,
                requestConfirmations: requestConfirmations,
                callbackGasLimit: callbackGasLimit,
                numWords: numWords,
                extraArgs: VRFV2PlusClient._argsToBytes(
                    VRFV2PlusClient.ExtraArgsV1({
                        nativePayment: enableNativePayment
                    })
                )
            })
        );
        s_requests[requestId] = RequestStatus({
            randomWords: new uint256[](0),
            exists: true,
            fulfilled: false,
            selectedStartIndex: 0,
            selectedEndIndex: 0
        });
        requestIds.push(requestId);
        lastRequestId = requestId;
        emit RequestSent(requestId, numWords);
        return requestId;
    }

    function fulfillRandomWords(
        uint256 _requestId,
        uint256[] calldata _randomWords
    ) internal override {
        require(s_requests[_requestId].exists, "request not found");
        s_requests[_requestId].fulfilled = true;
        s_requests[_requestId].randomWords = _randomWords;

        // Do something with the random words
        (uint16 startIndex, uint16 endIndex) = _selectRandomParticipants(
            numOfWinners,
            _randomWords[0]
        );
        s_requests[_requestId].selectedStartIndex = startIndex;
        s_requests[_requestId].selectedEndIndex = endIndex;
        emit RequestFulfilled(_requestId, _randomWords);
    }

    function getRequestStatus(
        uint256 _requestId
    ) external view returns (bool fulfilled, uint256[] memory randomWords) {
        require(s_requests[_requestId].exists, "request not found");
        RequestStatus memory request = s_requests[_requestId];
        return (request.fulfilled, request.randomWords);
    }

    function getSelectedParticipantsIndex(
        uint256 _requestId
    )
        external
        view
        returns (uint16 selectedStartIndex, uint16 selectedEndIndex)
    {
        require(s_requests[_requestId].exists, "request not found");
        RequestStatus memory request = s_requests[_requestId];
        return (request.selectedStartIndex, request.selectedEndIndex);
    }

    function isWinner(
        uint256 _requestId,
        address _participant
    ) external view returns (bool) {
        require(s_requests[_requestId].exists, "request not found");
        RequestStatus memory request = s_requests[_requestId];
        uint16 startIndex = request.selectedStartIndex;
        uint16 endIndex = request.selectedEndIndex;
        return
            participantsIndex[_participant] >= startIndex &&
            participantsIndex[_participant] <= endIndex;
    }

    // ========== internal functions ==========

    function _verifyMessage(
        address _to,
        string memory _message,
        uint256 _nonce,
        uint8 _v,
        bytes32 _r,
        bytes32 _s
    ) internal pure returns (address) {
        bytes32 hashedMessage = _getMessageHash(_to, _message, _nonce);
        bytes memory prefix = "\x19Ethereum Signed Message:\n32";
        bytes32 prefixedHashMessage = keccak256(
            abi.encodePacked(prefix, hashedMessage)
        );
        address recovedSigner = ecrecover(prefixedHashMessage, _v, _r, _s);
        return recovedSigner;
    }

    function _selectRandomParticipants(
        uint256 numToSelect,
        uint256 seed
    ) internal view returns (uint16 startIndex, uint16 endIndex) {
        require(numToSelect <= participants.length, "Not enough participants");
        seed %= participants.length;
        if (participants.length - seed < numToSelect) {
            startIndex = uint16(participants.length - numToSelect);
            endIndex = uint16(participants.length) - 1;
            return (startIndex, endIndex);
        }

        startIndex = uint16(seed);
        endIndex = uint16(seed + numToSelect) - 1;
    }

    function _getMessageHash(
        address _to,
        string memory _message,
        uint256 _nonce
    ) public pure returns (bytes32) {
        return keccak256(abi.encodePacked(_to, _message, _nonce));
    }
}
