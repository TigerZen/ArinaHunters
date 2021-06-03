
pragma solidity >= 0.4.25;

contract Manager{

    address public manager;

    constructor() public{
        manager = msg.sender;
    }

    modifier onlyManager{
        require(msg.sender == manager, "Is not owner");
        _;
    }

    function transferownership(address _new_manager) public onlyManager {
        manager = _new_manager;
    }
}

contract operator is Manager{

    mapping(string => address) OwnContracts;

    equ[] equs;

    struct equ{
        uint8 index;
        string name;
    }

    function inqContract(string name) public view returns(address){
        return OwnContracts[name];
    }

    function inqEquContract(uint8 equIndex) public view returns(address){
        for (uint8 i = 0; i < equs.length; i++) {
            if(equs[i].index == equIndex){
                return inqContract(equs[i].name);
            }
        }
    }

    function inqEqusAmount() public view returns(uint8){
        return uint8(equs.length);
    }

    function setAddress(string name, address contractAddress) public onlyManager{
        OwnContracts[name] = contractAddress;
    }

    function setEquAddress(uint8 equIndex, string name, address contractAddress) public onlyManager{
        setAddress(name, contractAddress);
        setEqu(equIndex, name);
    }

    function setEqu(uint8 equIndex, string name) private{
        equ memory newEqu = equ(equIndex, name);
        bool check;
        for (uint8 i = 0; i < equs.length; i++) {
            if(keccak256(abi.encodePacked(equs[i].name)) == keccak256(abi.encodePacked(name))||equs[i].index == equIndex){
                equs[i] = newEqu;
                check = true;
            }
        }
        if(!check){
            equs.push(newEqu);
        }
    }
}