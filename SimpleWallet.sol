// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v2.5.0/contracts/math/SafeMath.sol";

contract Allowance
{
    address public admin;
    uint public funds;
    uint withdrawLimit = 1 ether;

    modifier Owned
    {
        require(msg.sender == admin, "You do not have permission!");
        _;
    }

    mapping(address => User) public allowanceArray;

    struct User
    {
        uint amount;
        uint limit;
    }
}

contract SimpleWallet is Allowance
{
    using SafeMath for uint;

    event LimitEvent(string indexed _func, bool _status);
    event AddFunds(address indexed _from, uint _amount);
    event FundUser(address indexed _from, address indexed _to, uint _oldAmount, uint _newAmount);
    event WithdrawEvent(address indexed _who, address indexed _to, uint _oldAmount, uint _newAmount);


    constructor() 
    {
        admin = msg.sender;
    }

    function addFunds() 
     public
     payable
     Owned
    {
        funds = funds.add(msg.value);

        emit AddFunds(msg.sender, msg.value);
    }

    function alocateFunds(address _to, uint _amount)
     public
     Owned
    {
        require(funds - _amount > 0, "You do not have enough funds!");

        funds = funds.sub(_amount);
        allowanceArray[_to] = User(allowanceArray[_to].amount.add(_amount), withdrawLimit);

        emit FundUser(msg.sender, _to, allowanceArray[_to].amount - _amount, allowanceArray[_to].amount);
    }

    function withdraw(address payable _to, uint _amount)
     public 
     payable
    {
        User memory userInfo = allowanceArray[_to];
        require(userInfo.amount.sub(_amount) >= 0, "You do not have enough funds!");

        if(msg.sender == admin)
        {
           userInfo.amount = userInfo.amount.sub(_amount);
            _to.transfer(_amount);

            emit WithdrawEvent(msg.sender, _to, userInfo.amount + _amount, userInfo.amount);
        }
        else
        {
            require(_amount < userInfo.limit, "Your withdraw limit is of 1 ether! If you want to raise the limit contact the administrator!");
            
            userInfo.amount = userInfo.amount.sub(_amount);
            _to.transfer(_amount);

            emit WithdrawEvent(msg.sender, _to, userInfo.amount + _amount, userInfo.amount);
        }
    }

    function raiseLimit(address _to ,uint _amountToRaise)
     public
     Owned
    {
        allowanceArray[_to].limit = allowanceArray[_to].limit.add(_amountToRaise);
        
        emit LimitEvent("raiseLimit", true);
    }

    function resetLimit(address _to)
     public
     Owned
    {
        allowanceArray[_to].limit = withdrawLimit;

        emit LimitEvent("resetLimit", true);
    }

}