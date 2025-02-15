// SPDX-License-Identifier: MIT
pragma solidity >=0.8.17 <0.9.0;
import "@openzeppelin/contracts-upgradeable/access/Ownable2StepUpgradeable.sol";

contract HimCheckin is Ownable2StepUpgradeable{

    // map for user to checkin count
    mapping(address => UserInfo) public userCheckinInfo;

    uint32 public defaultCredit; // default credit for user
    uint32 public defaultCheckinInterval;
    uint32 public defaultVoteInterval; // default vote interval for user

    struct UserInfo{
        bool creditInit;
        uint64 creditNum;
        uint64 checkinTs;
        uint64 voteTs; // last vote timestamp
    }

    struct ActivityInfo{
        uint64 startTs;
        uint64 endTs;
        uint16 maxId; // max id
    }

    // activity list
    ActivityInfo[] public activityList;

    // map for ActivityIndex to maxId to voted num map
    mapping(uint256 => mapping(uint256 => uint256)) public activityVote;

    event CheckIn(address sender,uint256 checkinType);
    event ChangeDefaultCheckinInterval(uint32 oldCheckinInterval, uint32 newCheckinInterval);
    event DefaultVoteIntervalSet(uint256 oldDefaultVoteInterval, uint256 newVoteInterval);
    event DefaultCreditSet(uint256 oldDefaultCredit, uint256 newDefaultCredit);
    event ActivityEndTsModify(uint256 activityIndex, uint64 _endTs);
    event Vote(address user, uint256 activityIndex, uint256 id, uint32 credit);

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize() public initializer {
        __Ownable2Step_init();
        defaultCheckinInterval = 8*60*60;
        defaultVoteInterval = 8*60*60;
        defaultCredit = 10;
    }

    function changeDefaultCheckinInterval(uint32 newCheckinInterval) external onlyOwner{
        uint32 oldCheckinInterval = defaultCheckinInterval;
        defaultCheckinInterval = newCheckinInterval;
        emit ChangeDefaultCheckinInterval(oldCheckinInterval, newCheckinInterval);
    }

    function changeDefaultVoteInterval(uint32 newVoteInterval) external onlyOwner{
        uint32 oldDefaultVoteInterval = defaultVoteInterval;
        defaultVoteInterval = newVoteInterval;
        emit DefaultVoteIntervalSet(oldDefaultVoteInterval, newVoteInterval);
    }

    function changeDefaultCredit(uint32 newDefaultCredit) external onlyOwner{
        uint32 oldDefaultVote = defaultCredit;
        defaultCredit = newDefaultCredit;
        emit DefaultCreditSet(oldDefaultVote, newDefaultCredit);
    }

    function initializeUserCredit(address user) private{
        if(!userCheckinInfo[user].creditInit){
            // maybe have already checkin
            userCheckinInfo[user].creditNum = defaultCredit + userCheckinInfo[user].creditNum;
            userCheckinInfo[user].creditInit = true;
        }
    }

    // To add an activity
    function addActivity(uint64 _startTs, uint64 _endTs, uint16 _maxId) external onlyOwner(){
        ActivityInfo memory newActivity = ActivityInfo(_startTs, _endTs, _maxId);
        activityList.push(newActivity);
    }
    
    // modify specify activity endts
    function modifyActivityEndTs(uint256 _activityIndex, uint64 _endTs) external onlyOwner(){
        require(_activityIndex < activityList.length, "Invalid activity index");
        activityList[_activityIndex].endTs = _endTs;
        emit ActivityEndTsModify(_activityIndex, _endTs);
    }

    function activityListLength() public view returns(uint256){
        return activityList.length;
    }

    // getActivityInfo by id
    function getActivityInfo(uint256 activityIndex) public view returns(ActivityInfo memory){
        require(activityIndex < activityList.length, "Invalid activity index");
        ActivityInfo memory activity = activityList[activityIndex];
        return activity;
    }

    // vote to activity
    function vote(uint256 activityIndex, uint256 id, uint32 credit) public {
        initializeUserCredit(msg.sender);

        UserInfo memory newUserInfo = userCheckinInfo[msg.sender];

        require(newUserInfo.creditNum >= credit, 'user credit insufficient');
        unchecked{
            newUserInfo.creditNum -= credit;
        }

        // require user vote interval great than defaultVoteInterval
        if (newUserInfo.voteTs != 0){
            require((block.timestamp - newUserInfo.voteTs > defaultVoteInterval), "require vote interval");
        }

        require(activityIndex < activityList.length, "Invalid activity index");

        ActivityInfo memory activity = activityList[activityIndex];
        // require current time less than activity end time
        require(block.timestamp < activity.endTs, "Activity end");
        // require current time great than activity start time
        require(block.timestamp > activity.startTs, "Activity not start");
        // require question id less than max question id
        require(id <= activity.maxId, "Invalid question id");

        activityVote[activityIndex][id] += credit;
        newUserInfo.voteTs = uint64(block.timestamp);

        userCheckinInfo[msg.sender] = newUserInfo;

        emit Vote(msg.sender, activityIndex, id, credit);
    }

    function setIdVoteCount(uint256 activityIndex, uint256 id, uint32 credit) public onlyOwner(){
        require(activityIndex < activityList.length, "Invalid activity index");
        activityVote[activityIndex][id] = credit;
    }

    // get user credit
    function getCredit(address user) public view returns(uint256){
        if(!userCheckinInfo[user].creditInit){
            return defaultCredit;
        }else{
            return userCheckinInfo[user].creditNum;
        }
    }

    // checkinType is used to distinguish between different checkin types
    function checkIn(uint256 checkinType) public{
        initializeUserCredit(msg.sender);

        UserInfo memory currentUserInfo = userCheckinInfo[msg.sender];

        if (currentUserInfo.checkinTs != 0){
            require((uint64(block.timestamp) - currentUserInfo.checkinTs > defaultCheckinInterval), "checkin too often");
        }

        currentUserInfo.creditNum++;
        currentUserInfo.checkinTs = uint64(block.timestamp);
        userCheckinInfo[msg.sender] = currentUserInfo;
        emit CheckIn(msg.sender, checkinType);
    }

    uint256[50] private __gap;
}