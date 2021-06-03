pragma solidity >= 0.4.25;

import "./libraries/math.sol";
import "./libraries/OMD.sol";

contract CommonConstants {

    bytes4 constant internal ERC1155_ACCEPTED = 0xf23a6e61;
    // bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))
    bytes4 constant internal ERC1155_BATCH_ACCEPTED = 0xbc197c81;
    // bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))
}

interface ERC165 {

    function supportsInterface(bytes4 _interfaceId) external view returns (bool);
}

interface IERC1155 {

    event TransferSingle(address indexed _operator, address indexed _from, address indexed _to, uint256 tokenIndex, uint256 _value);
    event TransferBatch(address indexed _operator, address indexed _from, address indexed _to, uint256[] tokenIndexs, uint256[] _values);
    event ApprovalForAll(address indexed _owner, address indexed _operator, bool _approved);
    event URI(string _value, uint256 indexed tokenIndex);

    event Mint(address indexed to, uint256 id, uint256 amount);
    event Burn(address indexed from, uint256 id, uint256 amount);

    function safeTransferFrom(address _from, address _to, uint256 tokenIndex, uint256 _value, bytes  _data) external;
    function safeBatchTransferFrom(address _from, address _to, uint256[] tokenIndexs, uint256[] _values, bytes _data) external;
    function balanceOf(address _owner, uint256 tokenIndex) external view returns (uint256);
    function balanceOfBatch(address[] _owners, uint256[] tokenIndexs) external view returns (uint256[] memory);
    function setApprovalForAll(address _operator, bool _approved) external;
    function isApprovedForAll(address _owner, address _operator) external view returns (bool);
}

library Address {
    function isContract(address account) internal view returns (bool) {
        uint256 size;
        assembly{size := extcodesize(account)}
        return size > 0;
    }
}

interface ERC1155TokenReceiver {

    function onERC1155Received(address _operator, address _from, uint256 tokenIndex, uint256 _value, bytes  _data) external returns(bytes4);
    function onERC1155BatchReceived(address _operator, address _from,
    uint256[] tokenIndexs, uint256[]  _values, bytes  _data) external returns(bytes4);
}


interface chaTokenInterface{
    function getRandom() external returns(bytes32);
}

contract newMaterials is IERC1155, ERC165, CommonConstants, setOperator{

    using SafeMath for uint256;
    using SafeMath16 for uint16;
    using SafeMath8 for uint8;
    using Address for address;
    //address chaEx;
    //address chaToken;
    //address mix;

    // modifier onlychaEx{
    //     require(msg.sender == addr("chaEx"), "You are not chaEx Contract");
    //     _;
    // }
    
    modifier onlyX{
        require(msg.sender == addr("chaEx") || msg.sender == addr("personCall") || msg.sender == manager, "You are not chaEx Contract");
        _;
    }
    
    mapping (uint256 => mapping(address => uint256)) internal balances;
    mapping (address => mapping(address => bool)) internal operatorApproval;
    mapping (uint256 => uint256) internal totalSupply;

    mapping (uint256 => string) internal Drop2Name; //掉落物 => 名字
    mapping (uint256 => uint8) internal Drop2Grade; //掉落物 => 分級
    mapping (uint8 => uint256[]) internal Grade2Drop; //分級 => 掉落物
    mapping (uint => perProbability[]) internal Probability; //box => [(素材,機率), (素材,機率) ...]

    struct perProbability{
        uint tokenIndex;
        uint16 probability;
    }

/////////////////////////////////////////// ERC165 //////////////////////////////////////////////

    bytes4 constant private INTERFACE_SIGNATURE_ERC165 = 0x01ffc9a7;
    bytes4 constant private INTERFACE_SIGNATURE_ERC1155 = 0xd9b67a26;

//////////////////////////manager function///////////////////////

    // function setChaEx(address newAddress) public onlyManager{
    //     chaEx = newAddress;
    // }

    // function setchaToken(address newAddress) public onlyManager{
    //     chaToken = newAddress;
    // }

    // function setMix(address newAddress) public onlyManager{
    //     mix = newAddress;
    // }

    function setProbability(uint boxIndex, uint materialIndex, uint16 probability) public onlyManager{
        require(isBox(boxIndex), "It's not a box");
        perProbability memory p;
        p.tokenIndex = materialIndex;
        p.probability = probability;
        Probability[boxIndex].push(p);
    }

    function resetProbability(uint boxIndex, uint arrayIndex, uint materialIndex, uint16 probability) public{
        require(isBox(boxIndex), "It's not a box");
        perProbability memory p;
        p.tokenIndex = materialIndex;
        p.probability = probability;
        Probability[boxIndex][arrayIndex] = p;
    }

    function insertDropInfo(uint tokenIndex, string name, uint8 grade) public{
        Drop2Name[tokenIndex] = name;
        Drop2Grade[tokenIndex] = grade;
        Grade2Drop[grade].push(tokenIndex);
    }

//////////////////////////inquire function///////////////////////

    function drop2Name(uint index) public view returns(string){
        return Drop2Name[index];
    }

    function drop2Grade(uint index) public view returns(uint8){
        return Drop2Grade[index];
    }

    function grade2Drop(uint8 grade) public view returns(uint[]){
        return Grade2Drop[grade];
    }

/////////////////////////////////////////////////////////////////

    function getRandom() public returns(bytes32){
        uint256[1] memory m;
        assembly {
            if iszero(staticcall(not(0), 0xC327fF1025c5B3D2deb5e3F0f161B3f7E557579a, 0, 0x0, m, 0x20)) {
                revert(0, 0)
            }
        }
        return keccak256(abi.encodePacked(m[0]));
    }

    function isBox(uint boxIndex) public pure returns(bool){
        if(boxIndex.div(1000) == 1){
            return true;
        }
        else{
            return false;
        }
    }

    function isBoxMaterials(uint dropIndex) public pure returns(bool){
        if(dropIndex.div(1000) == 2){
            return true;
        }
        else{
            return false;
        }
    }

    function isDrop(uint dropIndex) public pure returns(bool){
        if(dropIndex.div(1000) == 7){
            return true;
        }
        else{
            return false;
        }
    }
    
    function openBox(uint boxIndex) public{
        require(isBox(boxIndex), "It's not a box");

        uint16 totProbability;
        for(uint16 i = 0; i < Probability[boxIndex].length; i++) {
            totProbability += Probability[boxIndex][i].probability;
        }
        uint16 lottery = uint16(getRandom()).mod(totProbability);

        uint getToken;
        uint16 currentNumber;
        for(uint16 j = 0; j < Probability[boxIndex].length; j++) {
            currentNumber += Probability[boxIndex][j].probability;
            if(currentNumber > lottery){
                getToken = Probability[boxIndex][j].tokenIndex;
                break;
            }
        }
        burn(boxIndex, msg.sender ,1);
        _mint(getToken, msg.sender, 1);
    }

    function open_many_box(uint boxIndex, uint amount) public{
        require(amount<2**16 && amount>0,"amount error!!!");

        for(uint16 m=0; m<amount; m++){
            openBox(boxIndex);
        }
    }

    function mint(uint256 tokenIndex, address to, uint256 _amount) public onlyX{
        _mint(tokenIndex, to, _amount);
    }

    function _mint(uint256 tokenIndex, address to, uint256 _amount) private{
        balances[tokenIndex][to] = balances[tokenIndex][to].add(_amount);
        totalSupply[tokenIndex] = totalSupply[tokenIndex].add(_amount);
        emit Mint(to, tokenIndex, _amount);
    }

    function burn(uint256 tokenIndex, address from, uint256 _amount) public{
        require(balances[tokenIndex][from] >= _amount, "You don't have enough balance");
        require(msg.sender == from || msg.sender == addr("mix"), "You don't have permission to burn");
        balances[tokenIndex][from] = balances[tokenIndex][from].sub(_amount);
        totalSupply[tokenIndex] = totalSupply[tokenIndex].sub(_amount);
        emit Burn(from, tokenIndex, _amount);
    }

    function perTotalSupply(uint256 tokenIndex) public view returns(uint amount){
        amount = totalSupply[tokenIndex];
    }

    function supportsInterface(bytes4 _interfaceId) public view returns (bool) {
        if (_interfaceId == INTERFACE_SIGNATURE_ERC165 ||
            _interfaceId == INTERFACE_SIGNATURE_ERC1155) {
        return true;
        }

        return false;
    }

    function safeTransferFrom(address _from, address _to, uint256 tokenIndex, uint256 _value, bytes  _data) external {

        require(_to != address(0x0), "_to must be non-zero.");
        require(_from == msg.sender || operatorApproval[_from][msg.sender] == true, "Need operator approval for 3rd party transfers.");
        balances[tokenIndex][_from] = balances[tokenIndex][_from].sub(_value);
        balances[tokenIndex][_to] = _value.add(balances[tokenIndex][_to]);

        emit TransferSingle(msg.sender, _from, _to, tokenIndex, _value);
        if (_to.isContract()) {
            _doSafeTransferAcceptanceCheck(msg.sender, _from, _to, tokenIndex, _value, _data);
        }
    }

    function safeBatchTransferFrom(address _from, address _to, uint256[]  tokenIndexs, uint256[]  _values, bytes  _data) external {

        require(_to != address(0x0), "destination address must be non-zero.");
        require(tokenIndexs.length == _values.length, "tokenIndexs and _values array lenght must match.");
        require(_from == msg.sender || operatorApproval[_from][msg.sender] == true, "Need operator approval for 3rd party transfers.");

        for (uint256 i = 0; i < tokenIndexs.length; ++i) {
            uint256 id = tokenIndexs[i];
            uint256 value = _values[i];

            balances[id][_from] = balances[id][_from].sub(value);
            balances[id][_to] = value.add(balances[id][_to]);
        }

        emit TransferBatch(msg.sender, _from, _to, tokenIndexs, _values);

        if (_to.isContract()) {
            _doSafeBatchTransferAcceptanceCheck(msg.sender, _from, _to, tokenIndexs, _values, _data);
        }
    }

    function balanceOf(address _owner, uint256 tokenIndex) external view returns (uint256) {
        return balances[tokenIndex][_owner];
    }

    function balanceOfBatch2(address _owner, uint256[] tokenIndexs) external view returns (uint256[] memory) {

        uint256[] memory balances_ = new uint256[](tokenIndexs.length);

        for (uint256 i = 0; i < tokenIndexs.length; ++i) {
            balances_[i] = balances[tokenIndexs[i]][_owner];
        }

        return balances_;
    }

    function balanceOfBatch(address[] _owners, uint256[] tokenIndexs) external view returns (uint256[] memory) {

        require(_owners.length == tokenIndexs.length, "Length is not seem");

        uint256[] memory balances_ = new uint256[](_owners.length);

        for (uint256 i = 0; i < _owners.length; ++i) {
            balances_[i] = balances[tokenIndexs[i]][_owners[i]];
        }

        return balances_;
    }

    function setApprovalForAll(address _operator, bool _approved) external {
        operatorApproval[msg.sender][_operator] = _approved;
        emit ApprovalForAll(msg.sender, _operator, _approved);
    }

    function isApprovedForAll(address _owner, address _operator) external view returns (bool) {
        return operatorApproval[_owner][_operator];
    }

/////////////////////////////////////////// Internal //////////////////////////////////////////////

    function _doSafeTransferAcceptanceCheck(address _operator, address _from,
    address _to, uint256 tokenIndex,uint256 _value, bytes memory _data) internal{

        require(ERC1155TokenReceiver(_to).onERC1155Received(_operator,
        _from, tokenIndex, _value, _data) == ERC1155_ACCEPTED,
        "contract returned an unknown value from onERC1155Received");
    }

    function _doSafeBatchTransferAcceptanceCheck(address _operator, address _from,
    address _to, uint256[] memory tokenIndexs, uint256[] memory _values, bytes memory _data) internal {

        require(ERC1155TokenReceiver(_to).onERC1155BatchReceived(_operator,
        _from, tokenIndexs, _values, _data) == ERC1155_BATCH_ACCEPTED,
        "contract returned an unknown value from onERC1155BatchReceived");
    }


    function require_material_probability(uint _boxIndex, uint _materialIndex)public view returns (uint, uint16){
        return (Probability[_boxIndex][_materialIndex-1].tokenIndex, Probability[_boxIndex][_materialIndex-1].probability);
    }
}