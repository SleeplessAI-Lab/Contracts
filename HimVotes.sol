// SPDX-License-Identifier: MIT
pragma solidity >=0.8.2;
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

contract HimVotes is OwnableUpgradeable{
    struct UserInfo{
        bool voteNumInit;
        uint32 voteNum; // current vote can use
        uint32 votedNum; // alread voted
        uint64 voteTs;
        uint32 referral; // one user one referral
        uint32 bindReferral;
    }

    uint32 public defaultVote;
    uint32 public defaultVoteInterval;
    uint32 private _currentReferral;

    mapping(uint256 => uint256) public himVote;
    // referral => user
    mapping(uint256 => address) public referralCode;
    mapping(address => UserInfo) public userInfoMap;

    uint256 public finishTs;

    event DefaultVoteSet(uint256 oldDefaultVote, uint256 newDefaultVote);
    event DefaultVoteInterval(uint256 oldDefaultVoteInterval, uint256 newVoteInterval);
    event VoteHim(address user, uint256 himId);
    event FinishTsSet(uint256 oldFinishTs, uint256 newFinishTs);

    function initialize() public initializer {
        __Ownable_init(msg.sender);
        defaultVote = 10;
        defaultVoteInterval = 86400;
        _currentReferral = 10000;
        // 2023-06-24 00:00:00 utc + 8
        finishTs = 1687536000;
    }

    function changeDefaultVoteInterval(uint32 newVoteInterval)  external onlyOwner{
        uint32 oldDefaultVoteInterval = defaultVoteInterval;
        defaultVoteInterval = newVoteInterval;
        emit DefaultVoteInterval(oldDefaultVoteInterval, newVoteInterval);
    }

    function changeDefaultVote(uint32 newDefaultVote)  external onlyOwner{
        uint32 oldDefaultVote = defaultVote;
        defaultVote = newDefaultVote;
        emit DefaultVoteSet(oldDefaultVote, newDefaultVote);
    }

    function changeFinishTs(uint256 newFinishTs)  external onlyOwner{
        uint256 oldFinishTs = finishTs;
        finishTs = newFinishTs;
        emit FinishTsSet(oldFinishTs, newFinishTs);
    }

    function initializeUserVote(address user) private{
        if(!userInfoMap[user].voteNumInit){
            userInfoMap[user].voteNum = defaultVote;
            userInfoMap[user].voteNumInit = true;
        }
    }

    function vote(uint256 himId, uint32 referral) public {
        require(block.timestamp < finishTs, 'activity finished');

        initializeUserVote(msg.sender);
        UserInfo memory newUserInfo = userInfoMap[msg.sender];

        // UserInfo memory newUserInfo = UserInfo(userInfoMap[msg.sender].voteNumInit, userInfoMap[msg.sender].voteNum, userInfoMap[msg.sender].voteTs, userInfoMap[msg.sender].referral,  userInfoMap[msg.sender].bindReferral);

        require(newUserInfo.voteNum > 0, 'user vote insufficient');

        // require user vote interval great than defaultVoteInterval, first 2 vote don't have restrict.
        if (newUserInfo.voteTs != 0 && newUserInfo.votedNum >=2){
            require((block.timestamp - newUserInfo.voteTs > defaultVoteInterval), "require vote interval");
        }

        if (newUserInfo.bindReferral != 0){
            require(newUserInfo.bindReferral==referral, "bind referral wrong");
        }

        // not bind
        if (referralCode[referral] != address(0)){
            address referralUser = referralCode[referral];
            // self referal
            if(referralUser == msg.sender){
                ++newUserInfo.voteNum;
            }else{
                ++userInfoMap[referralUser].voteNum;
            }
            newUserInfo.bindReferral = referral;
        }

        --newUserInfo.voteNum;
        ++newUserInfo.votedNum;
        ++himVote[himId];
        newUserInfo.voteTs = uint64(block.timestamp);

        userInfoMap[msg.sender] = newUserInfo;

        emit VoteHim(msg.sender, himId);
    }

    // generate
    function generateReferralCode() public{
        initializeUserVote(msg.sender);
        require(userInfoMap[msg.sender].referral == 0, "referral code exist");

        uint32 referal_value = _currentReferral;
        // set referral
        userInfoMap[msg.sender].referral = referal_value;
        referralCode[referal_value] = msg.sender;
        // increase
        ++_currentReferral;
    }

    uint256[49] private __gap;
}