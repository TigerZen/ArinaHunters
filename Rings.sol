pragma solidity >= 0.4.25;

import "./libraries/math.sol";
import "./libraries/OMD.sol";
import "./ERC721.sol";

interface mixInterface{
    function inquireEquInfo(uint8 _type,uint _id) external view returns(string equipt_name,uint8[3] boxIndex, 
                                                      uint8[3] materialIndex,uint[3] amount,uint8 rarity,uint8 equ_type);
                                                      
    function inquireEquAbility(uint8 _type,uint _id) external view returns(int16 atk_max,int16 atk_min,int16 def_max,int16 def_min, 
                                                      int16 hp_max,int16 hp_min);                                                 
}

contract Rings_token is setOperator, ERC721{

    using SafeMath for uint256;
    using SafeMath16 for uint16;

    // modifier onlychaContract{
    //     require(msg.sender == chaTokenContract || msg.sender == chaExContract, "You are not npc Contract");
    //     _;
    // }

    uint randomSeed;
    uint public idIndex;

    string public name;
    string public symbol;

    // address public chaTokenContract = 0x0;
    // address public chaExContract = 0x0;
    // address public synthesisContract = 0x0;
   
    // address public mix_address = 0x0;

    uint initialEqiAmount = 1000000;

    mapping (uint256 => address) internal _tokenOwner;
    mapping (uint256 => address) internal _tokenApprovals;
    mapping (address => uint) internal _ownedTokensCount;
    mapping (address => mapping (address => bool)) internal _operatorApprovals;

    mapping (address => uint[]) ownEqus; //查詢擁有的裝備

    ////////////以下mapping都要封裝!!!////////////

    mapping (uint => info) private equiptInfo;    //裝備名稱、類別、稀有度
    mapping (uint => status) private equiptStatus;  //是否裝備、裝備者
    mapping (uint => ability) private equiptAbility; //裝備攻擊、防禦、血量
    
    bytes4 private constant _INTERFACE_ID_ERC721 = 0x80ac58cd;

    struct info{
        string ItemName; //裝備名稱
        uint8 equiptType; //裝備類別
    }

    struct ability{
        uint8 rarity; //裝備稀有度 (0不存在, 1無能力值裝備, 2-7正常裝備)
        uint8 star; //稀有程度 (額外配料1個為1，依此類退最多為5)
        int16 atk; //攻擊
        int16 def; //防禦
        int16 hp;  //血量
    }

    struct status{ 
        bool isEquipped;  //是否裝備
        uint whoWear; //哪個角色穿戴
    }

    constructor () public {
        _registerInterface(_INTERFACE_ID_ERC721);

        name = "Rings";
        symbol = "Rings";
        randomSeed = uint((keccak256(abi.encodePacked(now))));
        idIndex = initialEqiAmount;
    }

/////////////////inquire function///////////////

    function totalSupply() public view returns (uint256){ return idIndex; } //裝備總量

    function inquireInfo(uint _id) public view returns(string _name, uint8 equiptType){
        if(_id <= initialEqiAmount && equiptInfo[_id].equiptType == 0){
            if(_id == 0){
                _name = "";
                equiptType = 0;
            }
            else{
                (_name, equiptType) = _iniEquInfo(_id);
            }
        }
        else{
            _name = equiptInfo[_id].ItemName;
            equiptType = equiptInfo[_id].equiptType;
        }
    }

    function inquireStatus(uint _id) public view returns(bool isEquipped, uint whoWear){
        if(_id <= initialEqiAmount && equiptStatus[_id].whoWear == 0){
            if(_id == 0){
                isEquipped = false;
                whoWear = 0;
            }
            else{
                (isEquipped, whoWear) = _iniEquStatus(_id);
            }
        }
        else{
            isEquipped = equiptStatus[_id].isEquipped;
            whoWear = equiptStatus[_id].whoWear;
        }
    }

    function inquireAbility(uint _id) public view returns(uint8 rarity,uint8 star, int16 atk, int16 def, int16 hp){
        if(_id <= initialEqiAmount && equiptAbility[_id].atk == 0){
            if(_id == 0){
                rarity = 0;
                star = 0;
                atk = 0;
                def = 0;
                hp = 0;
            }
            else{
                (rarity,star, atk, def, hp) = _iniEquAbility(_id);
            }
        }

        else{
            rarity = equiptAbility[_id].rarity;
            star = equiptAbility[_id].star;
            atk = equiptAbility[_id].atk;
            def = equiptAbility[_id].def;
            hp = equiptAbility[_id].hp;
        }
    }

    function inquireOwnEqu(address _address) public view returns(uint[] memory){
        return ownEqus[_address];
    }


//////////////initial equipment///////////////

    function _iniEquInfo(uint _id) private pure returns(string equName, uint8 equiptType){
        bytes32 random = keccak256(abi.encodePacked(_id,"Info"));
        equiptType = uint8(random[7])%3+1;
        if(equiptType == 1){
            equName = "Sword";
        }
        else if (equiptType == 2){
            equName = "Magic wand";
        }
        else if(equiptType == 3){
            equName = "Bow";
        }
        else{
            equName = "";
        }
    }

    function _iniEquStatus(uint _id) private pure returns(bool isEquipped, uint whoWear){
        isEquipped = true;
        whoWear = _id;
    }

    function _iniEquAbility(uint _id) private pure returns(uint8 rarity,uint8 star, int16 atk, int16 def, int16 hp){
        bytes32 random = keccak256(abi.encodePacked(_id,"Rank"));
        uint8 level = uint8(random[7]) % 50 + 1;
        uint8 random0 = uint8(random[10]) % 50;
        
        if(random0 < level){
            rarity = (level / 10) + 2;
            bytes1 random1 = random[11];
            bytes1 random2 = random[16];
            bytes1 random3 = random[19];
            bytes1 random4 = random[22];
            star = 0;    
            atk = (int16(random1) % 8 + 15 ) * (rarity - 1) + 8;
            def = (int16(random2) % 8 + 15) * (rarity - 1) ;
            hp =  ((int16(random3)+int16(random4)) % 10 + 80) * (rarity - 1) ;
        }
        else{
            rarity = 1;
            star = 0;
            atk = 0;
            def = 0;
            hp = 0;
        }
    }
    
    function inquire_mixContract() public view returns(address){
        return addr("mix");
    }

////////////////game function/////////////////

    function createEquipment(address _to,string _name, uint16 _id,uint8 _amount,uint8 _level) public {
        require(msg.sender == addr("mix"));
        idIndex = idIndex.add(1);
        _mint(_to, idIndex,_name,_id,_amount,_level);
    }

    function _mint(address to, uint256 tokenId,string _name, uint16 _id,uint8 amount,uint8 level) internal {
       //_id為合成武器裡的編號,amount為加入額外素材之數量,level角色合成等級
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");
        require(_tokenOwner[tokenId] == address(0));

        randomSeed++;
        _tokenOwner[tokenId] = to;

        //equList.push(tokenId);
        ownEqus[to].push(tokenId);

        _ownedTokensCount[to] = _ownedTokensCount[to].add(1);

        equiptInfo[tokenId].ItemName = _name;
        
        set_ability(tokenId,_id,amount);   //set 素質
   
        if(level == 6){             //等級達6等各素質+10%
            if(equiptAbility[tokenId].atk > 0){
                equiptAbility[tokenId].atk+= equiptAbility[tokenId].atk/10;
            }
            if(equiptAbility[tokenId].def > 0){
                equiptAbility[tokenId].def+= equiptAbility[tokenId].def/10;
            }
            if(equiptAbility[tokenId].hp> 0){
                equiptAbility[tokenId].hp+= equiptAbility[tokenId].hp/10;
            }
        }
        
        equiptAbility[tokenId].star = amount;
        equiptStatus[tokenId].isEquipped = false;

        emit Transfer(address(0), to, tokenId);
    }
    
    
    function set_ability(uint256 tokenId, uint16 _id, uint8 amount) internal{
        bytes32 random = (keccak256(abi.encodePacked("create", now, randomSeed)));
        
        (,,,,uint8 _rarity,uint8 _equ_type) = mixInterface(addr("mix")).inquireEquInfo(3,_id);
        (int16 atk_max,int16 atk_min,int16 def_max,int16 def_min,int16 hp_max,int16 hp_min) = mixInterface(addr("mix")).inquireEquAbility(3,_id);
         
        equiptAbility[tokenId].rarity = _rarity;
        equiptInfo[tokenId].equiptType = _equ_type;
        
        if(atk_max == 0 && atk_min == 0 ){
            equiptAbility[tokenId].atk = 0;
        }else{
            equiptAbility[tokenId].atk = int16(random[18]) % (atk_max-atk_min+1) + atk_min;
            if(equiptAbility[tokenId].atk > 0){
               equiptAbility[tokenId].atk+= (atk_max+atk_min)/5 * amount;
            }
        }
        
        if(def_max == 0 && def_min == 0 ){
            equiptAbility[tokenId].def = 0;
        }else{
            equiptAbility[tokenId].def = int16(random[20]) % (def_max-def_min+1) + def_min;
            if(equiptAbility[tokenId].def > 0){
               equiptAbility[tokenId].def+= (def_max+def_min)/5 * amount;
            }
        }
         
        if(hp_max == 0 && hp_min == 0 ){
            equiptAbility[tokenId].hp = 0;
        }else{
            equiptAbility[tokenId].hp = int16(random[22]) % (hp_max-hp_min+1) + hp_min;
            if(equiptAbility[tokenId].hp > 0){
               equiptAbility[tokenId].hp+= (hp_max+hp_min)/5 * amount;
            }
        }
  
    }
    

    function changeWhoWear(address caller, uint id, uint addEquID, uint removeEquID) public only("chaToken"){
        require(ownerOf(addEquID) == caller, "You don't have this equipment");
        require(addEquID != 0, "Id is 0");
        (bool isEquipped,)=inquireStatus(addEquID);
        require(isEquipped == false,"This equipment is Equipped");
        // if(removeEquID <= initialEqiAmount){
        //     equList.push(removeEquID);
        // }

        equiptStatus[addEquID].whoWear = id;
        equiptStatus[removeEquID].whoWear = 0;
        equiptStatus[addEquID].isEquipped = true;
        equiptStatus[removeEquID].isEquipped = false;
    }

    
///////////////////管理function/////////////////////

// function change_mixContract(address newAddress) public onlyManager{
//     mix_address = newAddress;
// }

// function changechaTokenContract(address newAddress) public onlyManager{
//     chaTokenContract = newAddress;
// }

// function changechaExContract(address newAddress) public onlyManager{
//     chaExContract = newAddress;
// }

/////////////////////ERC-721////////////////////////


    function balanceOf(address owner) public view returns (uint256) {
        require(owner != address(0), "ERC721: balance query for the zero address");
        if(owner == addr("chaEx")){
            return idIndex;
        }
        else{
            return _ownedTokensCount[owner];
        }
    }

    function ownerOf(uint256 tokenId) public view returns (address) {

        if(tokenId <= initialEqiAmount){
            if(tokenId == 0){
                revert("id 0 is null");
                }
            else{return addr("chaToken");}
        }
        else{
            address owner = _tokenOwner[tokenId];
            require(owner != address(0), "ERC721: owner query for nonexistent token");

            return owner;
        }
    }

    function approve(address to, uint256 tokenId) public {
        address owner = ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(msg.sender == owner || isApprovedForAll(owner, msg.sender),
            "ERC721: approve caller is not owner nor approved for all"
        );

        _tokenApprovals[tokenId] = to;
        emit Approval(owner, to, tokenId);
    }

    function getApproved(uint256 tokenId) public view returns (address) {
        require(_exists(tokenId), "ERC721: approved query for nonexistent token");

        return _tokenApprovals[tokenId];
    }

    function setApprovalForAll(address to, bool approved) public {
        require(to != msg.sender, "ERC721: approve to caller");

        _operatorApprovals[msg.sender][to] = approved;
        emit ApprovalForAll(msg.sender, to, approved);
    }

    function isApprovedForAll(address owner, address operator) public view returns (bool) {
        return _operatorApprovals[owner][operator];
    }


    function transferFrom(address from, address to, uint256 tokenId) public {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(msg.sender, tokenId), "ERC721: transfer caller is not owner nor approved");

        _transferFrom(from, to, tokenId);
    }


    function safeTransferFrom(address from, address to, uint256 tokenId) public {
        safeTransferFrom(from, to, tokenId, "");
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory _data) public {
        transferFrom(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
    }


    function _exists(uint256 tokenId) internal view returns (bool) {
        address owner = _tokenOwner[tokenId];
        return owner != address(0);
    }


    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view returns (bool) {
        require(_exists(tokenId), "ERC721: operator query for nonexistent token");
        address owner = ownerOf(tokenId);
        return (spender == owner || getApproved(tokenId) == spender || isApprovedForAll(owner, spender));
    }

    function _burn(address owner, uint256 tokenId) internal {
        require(ownerOf(tokenId) == owner, "ERC721: burn of token that is not own");

        _clearApproval(tokenId);

        _ownedTokensCount[owner].sub(1);
        _tokenOwner[tokenId] = address(0);

        emit Transfer(owner, address(0), tokenId);
    }
 
    function _burn(uint256 tokenId) internal {
        _burn(ownerOf(tokenId), tokenId);
    }

    function _transferFrom(address from, address to, uint256 tokenId) internal {
        require(ownerOf(tokenId) == from, "ERC721: transfer of token that is not own");
        require(to != address(0), "ERC721: transfer to the zero address");

        _clearApproval(tokenId);

        _ownedTokensCount[from].sub(1);
        _ownedTokensCount[to].add(1);

        _tokenOwner[tokenId] = to;

        ///更改擁有裝備列表
        ownEqus[to].push(tokenId);

        uint256[] storage fromEqus = ownEqus[from];
        for (uint256 i = 0; i < fromEqus.length; i++) {
            if (fromEqus[i] == tokenId) {
                break;
            }
        }
        assert(i < fromEqus.length);

        fromEqus[i] = fromEqus[fromEqus.length - 1];
        delete fromEqus[fromEqus.length - 1];
        fromEqus.length--;
        //////////////////////////////

        emit Transfer(from, to, tokenId);
    }

    function _checkOnERC721Received(address from, address to, uint256 tokenId, bytes memory _data)
        internal returns (bool)
    {
        if (!to.isContract()) {
            return true;
        }

        bytes4 retval = IERC721Receiver(to).onERC721Received(msg.sender, from, tokenId, _data);
        return (retval == _ERC721_RECEIVED);
    }

    function _clearApproval(uint256 tokenId) private {
        if (_tokenApprovals[tokenId] != address(0)) {
            _tokenApprovals[tokenId] = address(0);
        }
    }
}