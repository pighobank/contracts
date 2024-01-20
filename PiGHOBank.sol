// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

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

    function createDeposit(uint256 _amount, address _emergencyReleaseSigner, uint256 _periods) external {
        require(_periods > 0, "Periods should be greater than 0");

        deposits[msg.sender].push(Deposit({
            amount: 0,
            depositTimestamp: block.timestamp,
            withdrawnAmount: 0,
            emergencyReleaseSigner: _emergencyReleaseSigner,
            emergencyReleaseAmount: 0,
            periods: _periods
        }));

        addDeposit(deposits[msg.sender].length - 1, _amount);
    }

    function addDeposit(uint256 _depositIndex, uint256 _amount) public validDepositIndex(msg.sender, _depositIndex) {
        require(ghoToken.transferFrom(msg.sender, address(this), _amount), "Transfer failed");

        deposits[msg.sender][_depositIndex].amount += _amount;

        emit DepositOccurred(msg.sender, _amount);
    }

    function withdraw(uint256 _depositIndex, uint256 _amount, address _recipient)
    external validDepositIndex(msg.sender, _depositIndex) {
        Deposit storage userDeposit = deposits[msg.sender][_depositIndex];
        uint256 withdrawableAmount = getWithdrawableAmount(msg.sender, _depositIndex);

        require(_amount <= withdrawableAmount, "Exceeds withdrawable balance");

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
        require(userDeposit.amount - userDeposit.withdrawnAmount >= _amount, "Emergency release exceeds remaining amount");

        userDeposit.emergencyReleaseAmount += _amount;
        emit EmergencyReleasePerformed(_depositor, _amount);
    }

    function getWithdrawableAmount(address _depositor, uint256 _depositIndex)
    public view validDepositIndex(_depositor, _depositIndex) returns (uint256) {
        Deposit storage userDeposit = deposits[_depositor][_depositIndex];

        uint256 monthlyWithdrawAmount = ((block.timestamp >= userDeposit.depositTimestamp + 30 days)) ?
            ((block.timestamp - userDeposit.depositTimestamp) / 30 days) * userDeposit.amount / userDeposit.periods
            : 0;

        uint256 withdrawableAmount = monthlyWithdrawAmount + userDeposit.emergencyReleaseAmount - userDeposit.withdrawnAmount;
        return (withdrawableAmount >= userDeposit.amount) ? userDeposit.amount : withdrawableAmount;
    }
}
