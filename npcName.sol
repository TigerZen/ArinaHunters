pragma solidity >= 0.4.25;

import "./libraries/OMD.sol";

contract npcName is Manager{
    mapping(uint => name) Name;

    struct name{
        string FirstName;
        string MiddleName;
        string LastName;
        string NickName;
    }

    function insertName(uint index, string FirstName, string MiddleName, string LastName, string NickName) public onlyManager{
        Name[index].FirstName = FirstName;
        Name[index].MiddleName = MiddleName;
        Name[index].LastName = LastName;
        Name[index].NickName = NickName;
    }

    function inquireName(uint index) public view returns(string FirstName, string MiddleName, string LastName, string NickName){
        FirstName = Name[index].FirstName;
        MiddleName = Name[index].MiddleName;
        LastName = Name[index].LastName;
        NickName = Name[index].NickName;
    }

    function inquireFirstName(uint index) public view returns(string FirstName){
        FirstName = Name[index].FirstName;
    }

    function inquireMiddleName(uint index) public view returns(string MiddleName){
        MiddleName = Name[index].MiddleName;
    }

    function inquireLastName(uint index) public view returns(string LastName){
        LastName = Name[index].LastName;
    }

    function inquireNickName(uint index) public view returns(string NickName){
        NickName = Name[index].NickName;
    }
}