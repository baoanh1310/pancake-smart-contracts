// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./interfaces/IRandomNumberGenerator.sol";
import "./interfaces/IPancakeSwapLottery.sol";
import "./interfaces/IRandomizer.sol";

contract RandomNumberGenerator is IRandomNumberGenerator, Ownable {
    using SafeERC20 for IERC20;

    address public lottery;
    uint32 public randomResult;
    uint256 public latestRequestId;
    uint256 public latestLotteryId;

    IRandomizer public randomizer;

    /**
     * @notice Constructor
     * @dev RandomNumberGenerator must be deployed before the lottery.
     * Once the lottery contract is deployed, setLotteryAddress must be called.
     * @param _randomizerAddress: address of the Randomizer Contract
     */
    constructor(address _randomizerAddress) payable {
        randomizer = IRandomizer(_randomizerAddress);
    }

    /**
     * @notice Request randomness from a user-provided seed
     */
    function getRandomNumber() external override {
        require(msg.sender == lottery, "Only Lottery Contract");
        // Request a random number from the randomizer contract (50k callback limit)
        latestRequestId = randomizer.request(50000);
        // You can also do randomizer.request(50000, 20) to get a callback after 20 confirmations 
        // for increased finality security (you can do 1-40 confirmations).
    }

    /**
     * @notice Set the address for the Lottery Contract
     * @param _lottery: address of the Lottery Contract
     */
    function setLotteryAddress(address _lottery) external onlyOwner {
        lottery = _lottery;
    }

    /**
     * @notice It allows the admin to withdraw tokens sent to the contract
     * @param _tokenAddress: the address of the token to withdraw
     * @param _tokenAmount: the number of token amount to withdraw
     * @dev Only callable by owner.
     */
    function withdrawTokens(address _tokenAddress, uint256 _tokenAmount) external onlyOwner {
        IERC20(_tokenAddress).safeTransfer(address(msg.sender), _tokenAmount);
    }

    /**
     * @notice View latestLotteryId
     */
    function viewLatestLotteryId() external view override returns (uint256) {
        return latestLotteryId;
    }

    /**
     * @notice View random result
     */
    function viewRandomResult() external view override returns (uint32) {
        return randomResult;
    }

    // Callback function called by the randomizer contract when the random value is generated
    function randomizerCallback(uint256 _id, bytes32 _value) external {
        //Callback can only be called by randomizer
        require(msg.sender == address(randomizer), "Caller not Randomizer Protocol");
        randomResult = uint32(1000000 + (uint(_value) % 1000000));
        latestLotteryId = IPancakeSwapLottery(lottery).viewCurrentLotteryId();
    }
}