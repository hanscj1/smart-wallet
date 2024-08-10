// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract FeeManager is Ownable {
    using SafeERC20 for IERC20;

    uint256 public constant FEE_PRECISION = 1e6; // 1 millionth of a percent
    address public feeRecipient;

    event FeeCalculated(uint256 feeAmount);
    event FeeRecipientUpdated(address indexed oldRecipient, address indexed newRecipient);
    event FeeDistributed(address indexed token, uint256 amount);

    constructor(address _feeRecipient) Ownable(msg.sender) {
        require(_feeRecipient != address(0), "Invalid fee recipient");
        feeRecipient = _feeRecipient;
    }

    receive() external payable {}

    function setFeeRecipient(address _feeRecipient) external onlyOwner {
        require(_feeRecipient != address(0), "Invalid fee recipient");
        emit FeeRecipientUpdated(feeRecipient, _feeRecipient);
        feeRecipient = _feeRecipient;
    }

    function calculateFee(uint256 amount, uint256 feeBasisPoints) public pure returns (uint256) {
        require(feeBasisPoints <= FEE_PRECISION, "Fee basis points exceed maximum allowed");
        return (amount * feeBasisPoints) / FEE_PRECISION;
    }

    function distributeFee(address token) external {
        uint256 amount;
        if (token == address(0)) {
            // Distribute ETH
            amount = address(this).balance;
            (bool success, ) = feeRecipient.call{value: amount}("");
            require(success, "ETH fee distribution failed");
        } else {
            // Distribute ERC20 tokens
            amount = IERC20(token).balanceOf(address(this));
            IERC20(token).safeTransfer(feeRecipient, amount);
        }
        emit FeeDistributed(token, amount);
    }

    function rescueETH(uint256 amount) external onlyOwner {
        uint256 contractBalance = address(this).balance;
        require(contractBalance >= amount, "Insufficient balance to rescue");
        payable(owner()).transfer(amount);    
    }

    function rescueERC20(address token, uint256 amount) external onlyOwner {
        IERC20(token).safeTransfer(owner(), amount);
    }
}
