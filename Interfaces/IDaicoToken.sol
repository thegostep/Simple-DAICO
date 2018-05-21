pragma solidity ^0.4.23;

contract IDaicoToken {
  function balanceOf(address _owner) public view returns (uint256);
  function totalSupply() public view returns (uint256);
  function burnFrom(address _from, uint256 _value) public;
}
