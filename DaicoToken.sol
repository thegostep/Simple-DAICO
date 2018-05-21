pragma solidity ^0.4.23;

import "./zeppelin-contracts/BurnableToken.sol";
import "./zeppelin-contracts/StandardToken.sol";
import "./DAICO.sol";

contract DaicoToken is BurnableToken, StandardToken {

  DAICO public daicoContract;

  function deployDAICOContract(
    uint256 _initialTap,
    uint256 _votingPeriod,
    address _initialTapRecipient,
    address _owner
  ) public {
    daicoContract = new DAICO(_initialTap, _votingPeriod, _initialTapRecipient, _owner, address(this));
    address(daicoContract).transfer(address(this).balance);
  }

  function getETHBalance() public view returns (uint256) {
      return address(this).balance;
  }

  function burnFrom(address _from, uint256 _value) public {
    require(_value <= allowed[_from][msg.sender]);

    allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
    _burn(_from, _value);
  }

  function transfer(address _to, uint256 _value) public returns (bool) {
    require(daicoContract.callOnTransfer(msg.sender, _to, _value));
    require(_to != address(0));
    require(_value <= balances[msg.sender]);

    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    emit Transfer(msg.sender, _to, _value);
    return true;
  }

  function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
    require(daicoContract.callOnTransfer(_from, _to, _value));
    require(_to != address(0));
    require(_value <= balances[_from]);
    require(_value <= allowed[_from][msg.sender]);

    balances[_from] = balances[_from].sub(_value);
    balances[_to] = balances[_to].add(_value);
    allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
    emit Transfer(_from, _to, _value);
    return true;
  }
}
