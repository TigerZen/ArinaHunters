pragma solidity >= 0.4.25;

contract Migrations {
  // 標記合約的擁有者
  address public owner;

  // 該變量自動生成 `last_completed_migration()` 方法, 返回一個uint, 是必須的屬性.
  uint public last_completed_migration;

  modifier restricted() {
    if (msg.sender == owner) _;
  }

  function constructor() public{
    owner = msg.sender;
  }

  // `setCompleted(uint)` 方法是必須方法.
  function setCompleted(uint completed) public restricted {
    last_completed_migration = completed;
  }

  function upgrade(address new_address) public restricted {
    Migrations upgraded = Migrations(new_address);
    upgraded.setCompleted(last_completed_migration);
  }
}

///////////////////////////////////////////////
//////////////////不可以刪我////////////////////
///////////////////////////////////////////////