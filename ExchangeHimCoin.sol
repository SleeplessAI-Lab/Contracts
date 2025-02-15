// SPDX-License-Identifier: MIT
pragma solidity >=0.8.17 <0.9.0;
import "@openzeppelin/contracts-upgradeable/access/Ownable2StepUpgradeable.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";

contract ExchangeHimCoin is Ownable2StepUpgradeable{
    using Math for uint256;

    // map for msg.sender => userid
    mapping(address => string) public userIds;
    mapping(string => uint256) public himCoins;
    uint256 public bnbToHimCoinRate;

    event BindUserId(address sender, string userId);
    event SetBnbToHimCoinRate(uint256 oldBnbToHimCoinRate, uint256 newBnbToHimCoinRate);
    event BuyCoin(address sender, string userId, uint256 ethAmount, uint256 himCoinAmount);

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize() public initializer {
        __Ownable2Step_init();
        __Ownable_init_unchained(msg.sender);
        bnbToHimCoinRate = 100;
    }

    function setBnbToHimCoinRate(uint256 _bnbToHimCoinRate) external onlyOwner {
        uint256 oldBnbToHimCoinRate = bnbToHimCoinRate;
        bnbToHimCoinRate = _bnbToHimCoinRate;
        emit SetBnbToHimCoinRate(oldBnbToHimCoinRate, _bnbToHimCoinRate);
    }

    function withdrawETH(address to) external onlyOwner {
        (bool success, ) = to.call{value: address(this).balance}("");
        require(success, "withdrawETH error");
    }

    function bindUserId(string memory _userId) external {
        //require(bytes(userIds[msg.sender]).length == 0, "bound");
        userIds[msg.sender] = _userId;
        emit BindUserId(msg.sender, _userId);
    }

    function buyCoinsForExactETH() external payable {
        string memory _userId = userIds[msg.sender];
        require(bytes(_userId).length != 0, "not bound userId");
        uint256 himCoinAmount = previewCoinsForExactETH(msg.value);
        himCoins[_userId] += himCoinAmount;
        emit BuyCoin(msg.sender, _userId, msg.value, himCoinAmount);
    }

    function buyExactCoinsForETH(uint256 himCoinAmount) external payable {
        string memory _userId = userIds[msg.sender];
        require(bytes(_userId).length != 0, "not bound userId");
        uint256 ethAmount = previewExactCoinsForETH(himCoinAmount);
        require(msg.value == ethAmount, "eth amount error");
        himCoins[_userId] += himCoinAmount;
        emit BuyCoin(msg.sender, _userId, ethAmount, himCoinAmount);
    }

    function previewCoinsForExactETH(uint256 ethAmount) public view returns(uint256) {
        return ethAmount.mulDiv(bnbToHimCoinRate, 1e18, Math.Rounding.Floor);
    }

    function previewExactCoinsForETH(uint256 himCoinAmount) public view returns(uint256) {
        return himCoinAmount.mulDiv(1e18, bnbToHimCoinRate, Math.Rounding.Ceil);
    }

    fallback() external payable {}
    receive() external payable {}

    uint256[50] private __gap;
}