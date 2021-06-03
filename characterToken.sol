pragma solidity >= 0.4.25;

///////////////////////////////////////////////////////
//////////////////Character Token//////////////////////
///////////////////////////////////////////////////////

import "./ERC721.sol";
import "./libraries/OMD.sol";
import "./libraries/math.sol";

interface npcNameInterface {
    function inquireName(uint index) external view returns(string FirstName, string MiddleName, string LastName, string NickName);
    function inquireFirstName(uint index) external view returns(string FirstName);
    function inquireMiddleName(uint index) external view returns(string MiddleName);
    function inquireLastName(uint index) external view returns(string LastName);
    function inquireNickName(uint index) external view returns(string NickName);
}

interface dropInterface {
    function mint(uint256 _id, address _to, uint256 _amount) external;
    function drop2Name(uint index) external view returns(string);
    function drop2Grade(uint index) external view returns(uint8);
    function grade2Drop(uint8 grade) external view returns(uint[]);
}

interface equInterface{
    function changeWhoWear(address caller, uint chaId, uint addEquID, uint removeEquID) external;
    function safeTransferFrom(address from, address to, uint256 tokenId) external;
    function inquireStatus(uint chaId) external view returns(bool isEquipped, uint whoWear);
    function inquireAbility(uint chaId) external view returns(uint16 rarity, uint16 atk, uint16 def, uint16 hp);
}

interface chaExInterface{
    // function getRandom() external returns(bytes32);
    // function getViewRandom() external view returns(bytes32);
    function changelocation(uint chaId) external;
    function inquireStatus(uint chaId) external view returns(uint16 location, uint opponent, uint reviveTime, bool inBattle);
}

contract CharacterToken is ERC721, setOperator{

    using SafeMath for uint;
    using SafeMath16 for uint16;
    using SafeMath8 for uint8;
    //using npcLibrary for npc;

    // modifier only("chaEx"){
    //     require(msg.sender == addr("chaEx"),"You are not ChaEx Contract");
    //     _;
    // }

    // modifier onlyBattle{
    //     require(msg.sender == addr("battle"),"You are not Battle Contract");
    //     _;
    // }

    // address public addr("battle");
    // address public addr("chaEx");
    // address public addr("npcName");
    //address public dropContract;
    
    
    // mapping (uint8 => address) public equContract; //儲存裝備合約
    // uint8[] public ownEquContract; //擁有的裝備合約index

    uint randomSeed;
    uint public idIndex; //目前最新產生的id
    
    uint public totalSupply;            //角色總量(包含npc)
    uint public npcInitialCount = 1000000;   //npc 初始數量
    uint public npcCount;             //npc 數量

    uint8 public skillTypAmount;
    //mapping (uint8 => uint16) skillIndexAmount;

    // event fightResult(uint256 indexed attacker, uint exp, int money);

    ////////////以下mapping都要封裝!!!////////////

    mapping (address => uint) private ownedTokensId; //玩家所擁有的角色id(因一個地址只有一個玩家)

    mapping (uint => rank) private chaRank;          //角色等級、經驗
    mapping (uint => ability) private chaAbility;    //角色攻擊、防禦、血量
    mapping (uint => info) private chaInfo;          //角色名稱、頭像

    mapping (uint => mapping(uint8 => uint)) private chaEqu;   //角色裝備 Id => equType => equId
    mapping (uint => mapping(uint8 => bool)) private startChaEqu;   //npc裝備啟用

    mapping (uint => address) private chaBinding;    //角色綁定的玩家

    mapping (uint => bool) private npcElite; //儲存npc是否是菁英怪
    mapping (uint => bool) private npcBoss; //儲存npc是否為Boss


    constructor () public {
        name = "Character";   //該erc721名稱
        symbol = "Character"; //該erc721簡寫

        randomSeed = uint((keccak256(abi.encodePacked(now))));

        idIndex = npcInitialCount; //把id為0空下來
        npcCount = npcInitialCount;
        totalSupply = npcInitialCount;

    }

////////////   struct   /////////////

    struct rank {
        bool init;  //是否初始化參數

        uint16 level;  //等級
        uint exp; //經驗
        uint money;   //錢
    }

    struct ability {
        bool init;  //是否初始化參數

        uint16 atk; //攻擊
        uint16 def; //防禦
        uint16 hp;  //血量
    }

    struct info {
        //bool init;  //是否初始化參數

        string characterName;  //人物名稱
        uint8 avatar; //頭像
        uint8 ethnicity; //種族
        //uint8 career; //職業
        address binding; //npc綁定的玩家
    }

////////////manager function/////////////

    // function setEquContract(uint8 equType, address newAddress) public onlyManager{ //car => 0 item1 => 1 ...
    //     if(equContract[equType] == address(0)){
    //         ownEquContract.push(equType);
    //     }
    //     equContract[equType] = newAddress;
    // }

    // function delEquipmentField(uint8 equType) public onlyManager{ //car => 0 item1 => 1 ...
        
    //     equContract[equType] = address(0);  //沒有合約地址就沒有裝備欄位
    //     delete ownEquContract[ownEquContract.length-1];
    // }

    // function setchaExContract(address newAddress) public onlyManager{
    //     addr("chaEx") = newAddress;
    // }

    // function setNameContract(address newAddress) public onlyManager{
    //     addr("npcName") = newAddress;
    // }

    // function setSkill(uint8 typ) public onlyManager{
    //     skillTypAmount = typ;
    // }

    // function setBattleContract(address newAddress) public onlyManager{
    //     battle = newAddress;
    // }

    // function setDropContract(address newAddress) public onlyManager{
    //     dropContract = newAddress;
    // }

////////////// inquire function ///////////////

    // function inquireEquContract(uint8 equType) public view returns(address){
    //     return equContract[equType];
    // }

    // function inquireOwnEquContract() public view returns(uint8[]){
    //     return ownEquContract;
    // }

    function isNpc(uint chaId) public view returns(bool){  //確認角色是否為NPC
        
        if(chaId <= npcInitialCount && chaId != 0){
            return true;
        }
        else if(npcElite[chaId]){
            return true;
        }
        else if(npcBoss[chaId]){
            return true;
        }
        else if(_tokenOwner[chaId] == address(this)){
            return true;
        }
        else{return false;}
    }

    function inquireOwnedTokensId(address player) public view returns(uint chaId) {  //查詢玩家擁有角色id(一個玩家只能有一隻)
        chaId = ownedTokensId[player];
    }

    function inquireRank(uint chaId) public view returns(uint16 level, uint exp, uint money){  //查詢函數
        if(isNpc(chaId) && !chaRank[chaId].init){

            bytes32 random = keccak256(abi.encodePacked(chaId, "Rank"));
            if(npcElite[chaId]){
                level = uint16(random[6]).mod(50).add(30);
            }
            else if(npcBoss[chaId]){
                level = uint16(random[8]).mod(50).add(50);
            }
            else{
                level = uint16(random[7]).mod(50).add(1);
            }
                exp = 0;
                money = uint(random).mod((uint(level).mul(uint(1000).add(1)))).add(1000);
        }
        else{
            level = chaRank[chaId].level;
            exp = chaRank[chaId].exp;
            money = chaRank[chaId].money;
        }
    }

    function inquireAbility(uint chaId) public view returns(uint16 atk, uint16 def, uint16 hp){ //查詢原始能力值

        if(isNpc(chaId) && !chaAbility[chaId].init){

            uint16 x;

            (uint16 level,,) = inquireRank(chaId);
                bytes32 random = keccak256(abi.encodePacked(chaId,"Ability"));
                (uint16 random1, uint16 random2, uint16 random3) = (uint16(random[2]),uint16(random[4]),uint16(random[6]));

            if(npcElite[chaId]){
                x = 2;
            }
            else if(npcBoss[chaId]){
                x = 3;
            }
            else{
                x = 1;
            }
                atk = uint16(10).add((level-1).mul((random1.mod(6).add(5))).mul(x));
                def = uint16(10).add((level-1).mul((random2.mod(6).add(5))).mul(x));
                hp = uint16(100).add((level-1).mul((random3.mod(51).add(50))).mul(x));
        }
        else{
            atk = chaAbility[chaId].atk;
            def = chaAbility[chaId].def;
            hp = chaAbility[chaId].hp;
        }
    }

    function inquireInfo(uint chaId) public view returns(string characterName, uint8 avatar, uint8 ethnicity){ //查詢函數

        if(isNpc(chaId)){
            //(characterName, avatar, career) = npcInfo(chaId);
            bytes32 random = keccak256(abi.encodePacked(chaId,"Info"));
            avatar = uint8(random[15]).mod(10);
            ethnicity = uint8(random[7]).mod(10);
            characterName = "NPC";
        }
        else{
            characterName = chaInfo[chaId].characterName;
            avatar = chaInfo[chaId].avatar;
            ethnicity = chaInfo[chaId].ethnicity;
        }
    }

    function inquireEquipment(uint chaId, uint8 _equType) public view returns(uint equID){ //查詢函數
        if(isNpc(chaId) && !startChaEqu[chaId][_equType]){

            if(npcElite[chaId]){
                equID = 0;
            }
            else if(npcBoss[chaId]){
                equID = 0;
            }
            else{
                equID = chaId;
            }
        }
        else{
            equID = chaEqu[chaId][_equType];
        }
    }

    function inquireBinding(uint chaId) public view returns(address){ //查詢函數
        return(chaBinding[chaId]);
    }

    function inquireNpcNames(uint chaId) public view returns(string FirstName, string MiddleName,
        string LastName, string NickName){ //查詢函數
        require(isNpc(chaId), "Is not NPC");
        
        bytes32 random = keccak256(abi.encodePacked(chaId, "names"));
        
        uint16 FirstNameIndex = (uint16(random[18]).add(uint16(random[19]))).mod(300).add(1);
        uint16 MiddleNameIndex = (uint16(random[15]).add(uint16(random[16]))).mod(300).add(1);
        uint16 LastNameIndex = (uint16(random[12]).add(uint16(random[13]))).mod(300).add(1);
        uint16 NickNameIndex = (uint16(random[11]).add(uint16(random[10]))).mod(300).add(1);
    

        FirstName = npcNameInterface(addr("npcName")).inquireFirstName(FirstNameIndex);
        MiddleName = npcNameInterface(addr("npcName")).inquireMiddleName(MiddleNameIndex);
        LastName = npcNameInterface(addr("npcName")).inquireLastName(LastNameIndex);
        NickName = npcNameInterface(addr("npcName")).inquireNickName(NickNameIndex);
    }

    // function inquireNpcDrop(uint chaId) public view returns(uint[6]){
    //     if(isNpc(chaId)){
    //         bytes32 random = keccak256(abi.encodePacked(chaId, "Drop"));
    //         dropInterface drop = dropInterface(dropContract);
    //         return ([
    //             drop.grade2Drop(0)[uint(random[0]).mod(drop.grade2Drop(0).length)],
    //             drop.grade2Drop(1)[uint(random[1]).mod(drop.grade2Drop(1).length)],
    //             drop.grade2Drop(2)[uint(random[2]).mod(drop.grade2Drop(2).length)],
    //             drop.grade2Drop(3)[uint(random[3]).mod(drop.grade2Drop(3).length)],
    //             drop.grade2Drop(4)[uint(random[4]).mod(drop.grade2Drop(4).length)],
    //             drop.grade2Drop(5)[uint(random[5]).mod(drop.grade2Drop(5).length)]
    //             ]);
    //     }
    //     else{
    //         return([uint(0),uint(0),uint(0),uint(0),uint(0),uint(0)]);
    //     }
    // }

////////////// Create function //////////////

    function createCharacter(address player, string _name, uint8 avatar, uint8 ethnicity) public only("chaEx"){  //創建玩家角色
        require(_ownedTokensCount[player] == 0, "You already have character");
        _ownedTokensCount[player] = _ownedTokensCount[player].add(1);

        require(_tokenOwner[idIndex] == address(0), "This chaId already has owner");
        require(avatar <= 9);
        require(ethnicity <= 9);

        _tokenOwner[idIndex.add(1)] = player;  //token owner
        ownedTokensId[player] = idIndex.add(1);

        //bytes32 random = getRandom();

        chaRank[idIndex.add(1)].level = 1;

        chaRank[idIndex.add(1)].money = 1000;

        chaAbility[idIndex.add(1)].atk = 20000;
        chaAbility[idIndex.add(1)].def = 10;
        chaAbility[idIndex.add(1)].hp = 100;

        chaInfo[idIndex.add(1)].characterName = _name;
        chaInfo[idIndex.add(1)].avatar = avatar;
        chaInfo[idIndex.add(1)].ethnicity = ethnicity;

        chaExInterface(addr("chaEx")).changelocation(idIndex.add(1));

        chaBinding[idIndex.add(2)] = player;
        chaBinding[idIndex.add(3)] = player;
        chaBinding[idIndex.add(4)] = player;
        chaBinding[idIndex.add(5)] = player;
        chaBinding[idIndex.add(6)] = player;

        npcBoss[idIndex.add(2)] = true;
        npcElite[idIndex.add(3)] = true;
        npcElite[idIndex.add(4)] = true;
        npcElite[idIndex.add(5)] = true;
        npcElite[idIndex.add(6)] = true;

        idIndex = idIndex.add(6);

        emit Transfer(address(0), msg.sender, idIndex);
    }

///////////// Game function ///////////////

    function upgrade(uint chaId) public { //升等
        require(chaId == ownedTokensId[msg.sender] || msg.sender == addr("chaEx"),"It can't upgrade");
        (uint16 level, uint exp, uint money) = inquireRank(chaId);
        (uint16 atk, uint16 def, uint16 hp) = inquireAbility(chaId);

        require(exp >= level.mul(1000), "Exp is not enough");
        require(money >= level.mul(1000), "Money is not enough");

        chaRank[chaId].exp = exp.sub(level.mul(1000));
        chaRank[chaId].level = level.add(1);
        chaRank[chaId].money = money.sub(level.mul(1000));

        bytes32 newRandom = getRandom();

        chaAbility[chaId].atk = atk.add(uint16(newRandom[7]).mod(6).add(5));
        chaAbility[chaId].def = def.add(uint16(newRandom[12]).mod(6).add(5));
        chaAbility[chaId].hp = hp.add(uint16(newRandom[20]).mod(51).add(50));
        if(chaAbility[chaId].init == false || isNpc(chaId)){
            chaAbility[chaId].init = true;
        }
        if( chaRank[chaId].init == false || isNpc(chaId)){
            chaRank[chaId].init = true;
        }
    }

//////////// Equiment function /////////////////

    function payGC(uint chaId, uint GC) public only("chaEx"){
        (uint16 level, uint exp, uint money) = inquireRank(chaId);
        require(money >= GC, "Your don't have enough money");
        chaRank[chaId].money = money.sub(GC); //扣除角色id GC

        if(chaRank[chaId].init == false || isNpc(chaId)){
            chaRank[chaId].level = level;
            chaRank[chaId].exp = exp;
            chaRank[chaId].init = true;
        }
    }

    function changeEquipment(address player, uint chaId, uint8 equType, uint equId) public only("chaEx"){
        //require(ownerOf(chaId) == msg.sender,"yor are not owner"); //檢查是否擁有裝備角色
        require(ownerOf(chaId) == player || ownerOf(chaId) == address(this),
            "You can't change equipment of the character");
        require(chaId != 0, "Id is zero");
        require(equId != 0, "Equipment chaId is zero");
        require(equ(equType) != address(0),"Equipment Type is not exist");
        uint removeEquID = inquireEquipment(chaId, equType); //0為車, 1為武器...
        chaEqu[chaId][equType] = equId;
        if(!startChaEqu[chaId][equType] && isNpc(chaId)){
            startChaEqu[chaId][equType] = true;
        }
        
        equInterface(equ(equType)).changeWhoWear(player, chaId, equId, removeEquID);
    }

    function reward(uint chaId) public only("chaEx"){ //每天可領獎勵
        _addMoney(chaId, 5000);
    }

/////////////fighting function ////////////

    function _addExp(uint chaId, uint _exp) private{        //增加經驗值
        require(chaId != 0, "You need to create a character");

        (uint16 level, uint exp, uint money) = inquireRank(chaId);
        chaRank[chaId].exp = exp.add(_exp);
        //chaRank[chaId].money = money.add(_money);
        if(isNpc(chaId) && !chaRank[chaId].init){
            chaRank[chaId].money = money;
            chaRank[chaId].level = level;
            chaRank[chaId].init = true;
        }
    }

    function _addMoney(uint chaId, uint _money) private{
        require(chaId != 0, "You need to create a character");

        (uint16 level, uint exp, uint money) = inquireRank(chaId);
        chaRank[chaId].money = money.add(_money);
        if(isNpc(chaId) && !chaRank[chaId].init){
            chaRank[chaId].exp = exp;
            chaRank[chaId].level = level;
            chaRank[chaId].init = true;
        }
    }

    function _transferMoney(uint from, uint to, uint value) private{        //增加錢
        require(from != 0, "From is not exist");
        require(to != 0, "To is not exist");

        (uint16 fromLevel, uint fromExp, uint fromMoney) = inquireRank(from);
        chaRank[from].money = fromMoney.sub(value);
        
        if(isNpc(from) && !chaRank[from].init){
            chaRank[from].level = fromLevel;
            chaRank[from].exp = fromExp;
            chaRank[from].init = true;
        }

        (uint16 toLevel, uint toExp, uint toMoney) = inquireRank(to);
        chaRank[to].money = toMoney.add(value);

        if(isNpc(to) && !chaRank[to].init){
            chaRank[to].level = toLevel;
            chaRank[to].exp = toExp;
            chaRank[to].init = true;
        }
    }

    function addExp(uint chaId, uint _exp) public only("chaEx"){
        _addExp(chaId, _exp);
    }

    function addMoney(uint chaId, uint _money) public only("chaEx"){
        _addMoney(chaId, _money);
    }

    function transferMoney(uint from, uint to, uint value) public only("chaEx"){
        _transferMoney(from, to, value);
    }

    // function endFight(uint attacker, uint opponent, bool result) public onlyBattle{ //回傳戰鬥結果
        
    //     (uint16 opponentLevel,,) = inquireRank(opponent);
    //     (uint16 attackerLevel,,) = inquireRank(attacker);

    //     if(result){ //攻擊者獲勝

    //         uint value;
    //         uint dropId;

    //         uint8 random = uint8(getRandom()).mod(100);
    //         random = random.add(uint8(opponentLevel).div(2));  //Random掉落物數值

    //         uint[6] memory dropIndex = inquireNpcDrop(opponent);

    //         if(random <= 50){
    //             dropId = dropIndex[0];   //Random掉落物1-50數值獲得NPC掉落物Grande-0
    //         }
    //         else if(50 < random && random <= 80){
    //             dropId = dropIndex[1];   //Random掉落物51-80數值獲得NPC掉落物Grande-1
    //         }
    //         else if(80 < random && random <= 92){
    //             dropId = dropIndex[2];   //Random掉落物81-92數值獲得NPC掉落物Grande-2
    //         }
    //         else if(92 < random && random <= 97){
    //             dropId = dropIndex[3];   //Random掉落物93-97數值獲得NPC掉落物Grande-3
    //         }
    //         else if(97 < random && random <= 99){
    //             dropId = dropIndex[4];   //Random掉落物98-99數值獲得NPC掉落物Grande-4
    //         }
    //         else{
    //             dropId = dropIndex[5];   //Random掉落物100數值獲得NPC掉落物Grande-5
    //         }
            
    //         address _to = _tokenOwner[attacker];
    //         dropInterface(dropContract).mint(dropId, _to, 1);

    //         _addExp(attacker, uint(opponentLevel.mul(100)));
    //         _addExp(opponent, uint(attackerLevel.mul(10)));
            
    //         (,,uint opMoney) = inquireRank(opponent);
    //         value = opMoney.div(10);
    //         emit fightResult(attacker, opponentLevel.mul(100), int(value));
    //         _transferMoney(opponent, attacker, value);
    //     }
    //     else{   //攻擊者失敗

    //         addExp(opponent, uint(attackerLevel.mul(100)));
    //         addExp(attacker, uint(opponentLevel.mul(10)));

    //         (,,uint atkMoney) = inquireRank(attacker);
    //         value = atkMoney.div(10);
    //         emit fightResult(attacker, opponentLevel.mul(10), -int(value));
    //         _transferMoney(attacker, opponent, value);
    //     }
    // }

//////////////Other function//////////////

    function getRandom() public returns(bytes32){
        randomSeed += now;
        return keccak256(abi.encodePacked(block.difficulty, randomSeed));
    }

    // function onERC721Received(address operator, address from, uint256 tokenId, bytes memory data)
    //     public returns (bytes4){
    //         //實作接收function
    //         return _ERC721_RECEIVED;
    // }

/////////////// ERC721標準 ////////////////

    function balanceOf(address owner) public view returns (uint256) {
        require(owner != address(0), "ERC721: balance query for the zero address");
        if(owner == address(this)){
            return npcCount;
        }
        else{
            return _ownedTokensCount[owner];
        }
    }

    function ownerOf(uint256 tokenId) public view returns (address) {

        if(isNpc(tokenId)){
            return address(this);}
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
        require(_isApprovedOrOwner(msg.sender, tokenId), "ERC721: transfer caller is not owner nor approved");
        require(_ownedTokensCount[to] < 1, "Address can only has a character");

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
