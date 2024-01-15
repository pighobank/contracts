// SPDX-License-Identifier: MIT
pragma solidity ^0.5.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract PiGHOBank {
    IERC20 public ghoToken;

    struct Deposit {
        uint256 amount;
        uint256 depositTimestamp;
        uint256 withdrawnAmount;
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
        deposits[msg.sender].push(Deposit({
            amount: _amount,
            depositTimestamp: block.timestamp,
            withdrawnAmount: 0,
            emergencyReleaseSigner: _emergencyReleaseSigner,
            emergencyReleaseAmount: 0,
            periods: _periods
        }));
    }

    function withdraw(uint256 _depositIndex, uint256 _amount, address _recipient) public {
        require(_depositIndex < deposits[msg.sender].length, "Invalid deposit index");
        Deposit storage userDeposit = deposits[msg.sender][_depositIndex];

        uint256 monthlyWithdrawAmount = (block.timestamp - userDeposit.depositTimestamp) / 30 days * userDeposit.amount / userDeposit.periods;

        require(userDeposit.withdrawnAmount + _amount <= monthlyWithdrawAmount + userDeposit.emergencyReleaseAmount, "Exceeds withdrawal limits");

        require(userDeposit.amount - userDeposit.withdrawnAmount >= _amount, "Withdraw amount exceeds deposited amount");

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
