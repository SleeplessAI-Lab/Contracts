// SPDX-License-Identifier: MIT
// contracts/MerkleAirdrop.sol
pragma solidity 0.8.21;

import {MerkleProof} from "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract MerkleAirdrop is OwnableUpgradeable {
    using SafeERC20 for IERC20;

    bytes32 public merkleRoot;

    mapping(address => bool) public claimed;
    IERC20 public token;
    uint256 public startTS;
    uint256 public endTS;
    uint256 public claimedAmount;

    event ChangeEndTS(uint256 oldEndTS, uint256 newEndTS);
    event ChangeStartTS(uint256 oldStartTS, uint256 newStartTS);
    event ClaimAirdrop(address user, uint256 amount);
    event WithdrawRemainAirdrop(address owner, uint256 amount);

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(
        bytes32 _merkleRoot,
        address _token,
        uint256 _startTS,
        uint256 _endTS
    ) public initializer {
        __Ownable_init(msg.sender);
        require(_token != address(0), "token address 0");
        merkleRoot = _merkleRoot;
        token = IERC20(_token);
        startTS = _startTS;
        endTS = _endTS;
    }

    function claim(bytes32[] calldata proof, uint256 amount) external {
        require(claimed[msg.sender] == false, "already claimed");
        require(block.timestamp > startTS, "airdrop not start");
        require(block.timestamp < endTS, "airdrop has ended");
        require(verify(proof, amount, msg.sender), "invalid proof");

        claimed[msg.sender] = true;
        claimedAmount += amount;

        token.safeTransfer(msg.sender, amount);
        emit ClaimAirdrop(msg.sender, amount);
    }

    function verify(
        bytes32[] calldata proof,
        uint256 amount,
        address account
    ) public view returns (bool) {
        bytes32 leaf = keccak256(abi.encodePacked(account, amount));
        return MerkleProof.verify(proof, merkleRoot, leaf);
    }

    function changeEndTS(uint256 _endTS) external onlyOwner {
        uint256 oldEndTS = endTS;
        endTS = _endTS;
        emit ChangeEndTS(oldEndTS, endTS);
    }

    function changeStartTS(uint256 _startTS) external onlyOwner {
        uint256 oldStartTS = startTS;
        startTS = _startTS;
        emit ChangeStartTS(oldStartTS, startTS);
    }

    function withdraw(uint256 amount) external onlyOwner {
        require(block.timestamp > endTS, "airdrop not end");
        token.safeTransfer(msg.sender, amount);
        emit WithdrawRemainAirdrop(msg.sender, amount);
    }

    uint256[50] private __gap;
}
