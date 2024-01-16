// SPDX-License-Identifier: MIT
pragma solidity ^0.5.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract PiGHOBank {
    IERC20 public ghoToken;

    struct Deposit {
        uint256 amount;
        uint256 depositTimestamp;
        uint256 withdrawnAmount;
        uint256 deductedPenalties;
        address emergencyReleaseSigner;
        uint256 emergencyReleaseAmount;
        uint256 periods;
    }

    mapping(address => Deposit[]) public deposits;

    constructor(IERC20 _ghoToken) public {
        ghoToken = _ghoToken;
    }

    function deposit(uint256 _amount, address _emergencyReleaseSigner, uint256 _periods) public {
        require(_periods > 0, "Periods should be greater than 0");
        require(ghoToken.transferFrom(msg.sender, address(this), _amount), "Transfer failed");

        if (_amount >= penalties[msg.sender] && _periods >= 3) {
            _amount += penalties[msg.sender];
            penalties[msg.sender] = 0;
        }

        deposits[msg.sender].push(Deposit({
            amount: _amount,
            depositTimestamp: block.timestamp,
            withdrawnAmount: 0,
            deductedPenalties: 0,
            emergencyReleaseSigner: _emergencyReleaseSigner,
            emergencyReleaseAmount: 0,
            periods: _periods
        }));
    }

    function withdraw(uint256 _depositIndex, uint256 _amount, address _recipient) public {
        require(_depositIndex < deposits[msg.sender].length, "Invalid deposit index");
        Deposit storage userDeposit = deposits[msg.sender][_depositIndex];
        uint256 depositAmountAfterDeductingPenalties = userDeposit.amount - userDeposit.deductedPenalties;
        uint256 withdrawableBalance = ((block.timestamp - userDeposit.depositTimestamp) / 30 days * depositAmountAfterDeductingPenalties / userDeposit.periods + userDeposit.emergencyReleaseAmount) - userDeposit.withdrawnAmount;

        if(withdrawableBalance > depositAmountAfterDeductingPenalties) {
            withdrawableBalance = depositAmountAfterDeductingPenalties;
        }

        if(_amount > withdrawableAmount * 90 / 100) {
            uint256 remainingAmount = userDeposit.amount - withdrawableAmount;
            uint256 penalty = remainingAmount * 10 / 100;
            penalties[msg.sender] += penalty;
            userDeposit.deductedPenalties += penalty;
        }

        require(_amount <= withdrawableBalance, "Exceeds withdrawable balance");

        require(ghoToken.transfer(_recipient, _amount), "Transfer failed");

        userDeposit.withdrawnAmount += _amount;
    }

    function getDepositsCount(address _user) public view returns (uint256) {
        return deposits[_user].length;
    }

    function emergencyRelease(address _depositor, uint256 _depositIndex, uint256 _amount) public {
        require(_depositIndex < deposits[_depositor].length, "Invalid deposit index");
        Deposit storage userDeposit = deposits[_depositor][_depositIndex];

        require(msg.sender == userDeposit.emergencyReleaseSigner, "Only the emergency release signer can call this function");
        require(userDeposit.amount - userDeposit.withdrawnAmount >= _amount, "Emergency release exceeds remaining amount");

        userDeposit.emergencyReleaseAmount += _amount;
    }
}
