// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract PiGHOBank {

    IERC20 public ghoToken;
    uint256 public constant PENALTY_RATE = 10;

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
    mapping(address => uint256) public penalties;

    event DepositOccurred(address owner, uint256 amount);
    event WithdrawalProcessed(address owner, uint256 amount, address recipient);
    event EmergencyReleasePerformed(address depositor, uint256 amount);

    modifier validDepositIndex(address _user, uint256 _depositIndex) {
        require(_depositIndex < deposits[_user].length, "Invalid deposit index");
        _;
    }

    constructor(IERC20 _ghoToken) {
        ghoToken = _ghoToken;
    }

    function deposit(uint256 _amount, address _emergencyReleaseSigner, uint256 _periods) external {
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

        emit DepositOccurred(msg.sender, _amount);
    }

    function withdraw(uint256 _depositIndex, uint256 _amount, address _recipient)
    external validDepositIndex(msg.sender, _depositIndex) {
        Deposit storage userDeposit = deposits[msg.sender][_depositIndex];
        uint256 withdrawableAmount = getWithdrawableAmount(_depositIndex);

        require(_amount <= withdrawableAmount, "Exceeds withdrawable balance");

        if (_amount > withdrawableAmount - userDeposit.emergencyReleaseAmount) * 90 / 100) {
        uint256 remainingAmount = userDeposit.amount - userDeposit.withdrawnAmount - userDeposit.deductedPenalties;
        uint256 penalty = remainingAmount * PENALTY_RATE / 100;

        penalties[msg.sender] += penalty;
        userDeposit.deductedPenalties += penalty;
        }

        require(ghoToken.transfer(_recipient, _amount), "Transfer failed");
        userDeposit.withdrawnAmount += _amount;

        emit WithdrawalProcessed(msg.sender, _amount, _recipient);
    }

    function getDepositsCount(address _user) external view returns (uint256) {
        return deposits[_user].length;
    }

    function emergencyRelease(address _depositor, uint256 _depositIndex, uint256 _amount)
    external validDepositIndex(_depositor, _depositIndex) {
        Deposit storage userDeposit = deposits[_depositor][_depositIndex];

        require(msg.sender == userDeposit.emergencyReleaseSigner, "Only the emergency release signer can call this function");
        require(userDeposit.amount - userDeposit.withdrawnAmount - userDeposit.deductedPenalties >= _amount, "Emergency release exceeds remaining amount");

        userDeposit.emergencyReleaseAmount += _amount;

        emit EmergencyReleasePerformed(_depositor, _amount);
    }

    function getWithdrawableAmount(uint256 _depositIndex)
    public view validDepositIndex(msg.sender, _depositIndex) returns (uint256) {
        Deposit storage userDeposit = deposits[msg.sender][_depositIndex];
        uint256 adjustedDeposit = userDeposit.amount - userDeposit.deductedPenalties;

        uint256 monthlyWithdrawAmount = ((block.timestamp >= userDeposit.depositTimestamp + 30 days)) ?
            ((block.timestamp - userDeposit.depositTimestamp) / 30 days) * adjustedDeposit / userDeposit.periods
            : 0;

        uint256 withdrawableAmount = monthlyWithdrawAmount + userDeposit.emergencyReleaseAmount - userDeposit.withdrawnAmount;
        return (withdrawableAmount >= adjustedDeposit) ? adjustedDeposit : withdrawableAmount;
    }
}
