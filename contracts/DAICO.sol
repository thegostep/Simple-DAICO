pragma solidity ^0.4.23;

import './zeppelin-contracts/SafeMath.sol';
import './Interfaces/IDaicoToken.sol';
import './Vote.sol';

contract DAICO {

  using SafeMath for uint256;

  address public owner;
  IDaicoToken public tokenContract;
  Vote public voteContract;

  constructor(
    uint256 _tap,
    uint256 _votingPeriod,
    address _tapRecipient,
    address _owner,
    address _tokenContract
  ) public payable {
    tap = _tap;
    votingPeriod = _votingPeriod;
    tapRecipient = _tapRecipient;
    owner = _owner;
    tokenContract = IDaicoToken(_tokenContract);
  }

  function() public payable {}

  function getETHBalance() public view returns (uint256) {
      return address(this).balance;
  }

/////////////////////////////////////////////
// This section contains logic for the tap //
/////////////////////////////////////////////

  uint256 public tap; // wei per second
  uint256 public lastWithdrawTime = now;
  address public tapRecipient;

  function getAccumulatedTap() public view returns(uint256) {
    uint256 amountWei = uint256(tap.mul(now.sub(lastWithdrawTime)));
    if(address(this).balance < amountWei) {
      amountWei = address(this).balance;
    }
    return amountWei;
  }

  function claimAccumulatedTap() public notRefund {
    require(msg.sender == owner);
    require(_payout());
  }

  function changeTapRecipient(address _newTapRecipient) public notRefund {
    require(msg.sender == owner);
    tapRecipient = _newTapRecipient;
  }

  function _payout() private notRefund returns (bool){
    uint256 amountWei = getAccumulatedTap();
    lastWithdrawTime = now;
    tapRecipient.transfer(amountWei);
    return true;
  }

///////////////////////////////////////////////////
// This section contains logic for token refunds //
///////////////////////////////////////////////////

  bool public activeRefund = false;

  modifier notRefund() {
    require(!activeRefund);
    _;
  }

  // Requires token holder to first approve this contract for full token balance transfer
  function refundTokens() public {
    uint256 tokenHolderBalance = tokenContract.balanceOf(msg.sender);
    require(tokenHolderBalance > 0);
    require(activeRefund);
    uint256 refundValue = (tokenHolderBalance.mul(address(this).balance)).div(tokenContract.totalSupply());
    require(refundValue > 0);
    tokenContract.burnFrom(msg.sender,tokenHolderBalance);
    msg.sender.transfer(refundValue);
  }

////////////////////////////////////////////////
// This section contains logic for governance //
////////////////////////////////////////////////

  bool public activeTapVote = false;
  bool public activeRefundVote = false;
  uint256 public votingPeriod;
  uint256 public proposedTapIncrease;

  function activeVote() public view returns (bool) {
    if (activeTapVote || activeRefundVote) {
      return true;
    }
    return false;
  }

  function startTapVote(uint256 _proposedIncrease) public notRefund {
    require(msg.sender == owner);
    require(!activeVote());
    activeTapVote = true;
    proposedTapIncrease = _proposedIncrease;
    voteContract = new Vote(now.add(votingPeriod), address(this), address(tokenContract));
  }

  function startRefundVote() public notRefund {
    require(tokenContract.balanceOf(msg.sender) > 0);
    require(!activeVote());
    activeRefundVote = true;
    voteContract = new Vote(now.add(votingPeriod), address(this), address(tokenContract));
  }

  function finalizeTapVote() public notRefund {
    require(activeTapVote);
    bool result = voteContract.finalResult();
    if (result) {
      require(_payout());
      tap = tap.add(proposedTapIncrease);
    }
    activeTapVote = false;
    proposedTapIncrease = 0;
    delete voteContract;
  }

  function finalizeRefundVote() public notRefund {
    require(activeRefundVote);
    bool result = voteContract.finalResult();
    if (result) {
      activeRefund = true;
    }
    activeRefundVote = false;
    delete voteContract;
  }

  function callOnTransfer(address _sender, address _receiver, uint256 _amount) public returns (bool) {
    require(msg.sender == address(tokenContract));
    if (activeVote()) {
      require(voteContract.callOnTransfer(_sender,_receiver,_amount));
    }
    return true;
  }
}
