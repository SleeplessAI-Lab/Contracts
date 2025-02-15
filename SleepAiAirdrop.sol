// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.17 <0.9.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract SleepAiAirdrop {
    IERC20 public token;

    event BatchAirdrop(
        address indexed sender,
        address[] recipients,
        uint256[] amounts
    );

    constructor(IERC20 _token) {
        token = _token;
    }

    function batchAirdrop(
        address[] calldata recipients,
        uint256[] calldata amounts
    ) external {
        require(
            recipients.length == amounts.length,
            "SleepAiAirdrop: Invalid input"
        );
        for (uint256 i = 0; i < recipients.length; i++) {
            token.transferFrom(msg.sender, recipients[i], amounts[i]);
        }
        emit BatchAirdrop(msg.sender, recipients, amounts);
    }
}
