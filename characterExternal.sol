pragma solidity >= 0.4.25;

///////////////////////////////////////////////////////
/////////////////Character External////////////////////
///////////////////////////////////////////////////////

import "./ERC721.sol";
import "./libraries/OMD.sol";
import "./libraries/math.sol";

interface InstanceInterface{
    function ready(uint attacker, uint16 level) external;
}

interface battleInterface{
    function ready(uint attacker, uint opponent) external;
}

interface newMaterialsInterface {
    function balanceOf(address _owner, uint256 _id) external view returns (uint256);
    function drop2Name(uint index) external view returns(string);
    function drop2Grade(uint index) external view returns(uint8);
    function grade2Drop(uint8 grade) external view returns(uint[]);
    function mint(uint256 tokenIndex, address to, uint256 _amount) external;
}

interface equInterface{
    function ownerOf(uint256 tokenId) external view returns (address owner);
    function changeWhoWear(address caller, uint chaId, uint addEquID, uint removeEquID) external;
    function safeTransferFrom(address from, address to, uint256 tokenId) external;
    function inquireInfo(uint _id) external view returns(string _name, uint8 equiptType);
    function inquireStatus(uint chaId) external view returns(bool isEquipped, uint whoWear);
    function inquireAbility(uint chaId) external view returns(uint8 rarity, uint8 star, int16 atk, int16 def, int16 hp);
    function inquireOwnEqu(address _address) public view returns(uint[] memory);
}

interface chaTokenInterface {
    function addExp(uint chaId, uint _exp) external;
    function addMoney(uint chaId, uint _money) external;
    function transferMoney(uint from, uint to, uint value) external;

    function payGC(uint chaId, uint GC) external;
    function ownerOf(uint256 tokenId) external view returns (address owner);
    function isNpc(uint chaId) external view returns(bool);
    function isAlife(uint chaId) external view returns(bool);
    function inquireOwnedTokensId(address player) external view returns(uint chaId);

    function inquireRank(uint chaId) external view returns(uint16 level, uint exp, uint money);
    function inquireAbility(uint chaId) external view returns(uint16 atk, uint16 def, uint16 hp);
    //function inquireTotAbility(uint chaId) external view returns(uint16 atk, uint16 def, uint16 hp);
    function inquireInfo(uint chaId) external view returns(string characterName, uint8 avatar, uint8 career);
    
    function inquireEquipment(uint chaId, uint8 _equType) external view returns(uint equID);
    //function inquireEquContract(uint8 equType) external view returns(address);
    //function inquireOwnEquContract() external view returns(uint8[]);

    function inquireBinding(uint chaId) external view returns(address);

    function inquireNpcNames(uint chaId) external view returns(string FirstName, string MiddleName,
        string LastName, string NickName);

    //function inquireNpcDrop(uint chaId) external view returns(uint[6]);

    //function inquireSkill(uint chaId, uint8 term)external view returns(uint8 level, uint8 typ, uint8 index);

    function getRandom() external returns(bytes32);
    //function getViewRandom() external view returns(bytes32);

    //function endFight(uint attacker, uint opponent, bool result) external;

    function idIndex() external view returns(uint);
    function totalSupply() external view returns(uint);

    function npcInitialCount() external view returns(uint);
    function npcCount() external view returns(uint);

    function equfeild() external view returns(uint);

    function createCharacter(address player, string _name, uint8 avatar, uint8 ethnicity) external payable;
    function upgrade(uint chaId) external;
    function changeEquipment(address player, uint chaId, uint8 equType, uint equId) external;
    function reward(uint chaId) external;
}

contract CharacterExternal is setOperator{

    using SafeMath for uint256;
    using SafeMath16 for uint16;
    using SafeMath8 for uint8;

    // address public addr("chaToken");  //角色ERC721合約
    // //address public equ; //裝備合約(改由其他函數)
    // address public battle; //戰鬥合約
    // address public addr("newMats"); //新素材合約
    
    // //address public dropContract; //掉落合約
    // // address public treasure; //寶箱合約
    // // address public material; //素材合約
    // address public instance; //副本合約

    uint16 public landCount = 1600;          //土地總數
    uint public fightingId ; //戰鬥編號

    // modifier onlychaTokenContract{
    //     require(msg.sender == addr("chaToken"), "You are not addr("chaToken") Contract");
    //     _;
    // }

    modifier onlyBattle{
        require(msg.sender == addr("battle"),"You are not Battle Contract");
        _;
    }

    // modifier onlyInstance{
    //     require(msg.sender == instance,"You are not instance Contract");
    //     _;
    // }

    mapping (uint8 => mapping(uint => uint)) public equPrice; //裝備價格
    //mapping (uint => uint[]) public pairWith; //玩家會配對到五隻npc

    mapping (uint => status) private chaStatus;      //角色狀態
    //mapping (uint => fighting) private fightingRecord; //戰鬥紀錄(攻擊者 => 戰鬥)
    //mapping (uint => uint) private fightingId;
    mapping (uint => uint[5]) private pairWith; //玩家會配對到五隻npc戰鬥狀態

    //mapping (uint => uint) private locationOwnCharacter; //紀錄該地點有那些人物 (初始NPC已完成)

    mapping (uint8 => matProbability[]) public matPrb; //box => [(素材,機率), (素材,機率) ...]

    event fightResult(uint256 indexed attacker, uint exp, int money);

////////////   struct   /////////////

    struct matProbability {
        uint8 matIndex; //素材index
        uint16 probability; //買素材獲得機率
    }

    struct fighting {
        bool start; //是否開始
        uint opponent; //敵人id
        bool result; //結果,true為攻擊者獲勝
    }

    struct status {
        bool init;  //是否初始化參數

        uint16 location; //所在地
        uint64 rewardCoolTime; //領獎勵冷卻時間(可正常調用時間)
        uint64 reviveTime; //復活時間(npc不用)
        bool inBattle; //是否在戰鬥(npc不用)
        bool inInstance; //是否在副本
    }

    constructor() public{
        fightingId = 0;
    }


////////////// manager function////////////////

    function setEquPrice(uint8 equType, uint equID, uint Price) public onlyManager{
        equPrice[equType][equID] = Price; //GC(沒有小數點)
    }

    // function setChaTokenContract(address newAddress) public onlyManager{
    //     addr("chaToken") = newAddress;
    // }

    // function setBattle(address newAddress) public onlyManager{
    //     addr("battle") = newAddress;
    // }

    // function setLandCount(uint16 newLandCount) public onlyManager{
    //     landCount = newLandCount;
    // }

    // function setNewMaterials(address newAddress) public onlyManager{
    //     addr("newMats") = newAddress;
    // }

    // function setTreasure(address newAddress) public onlyManager{
    //     treasure = newAddress;
    // }

    // function setMaterial(address newAddress) public onlyManager{
    //     Materials = newAddress;
    // }

    // function setInstance(address newAddress) public onlyManager{
    //     instance = newAddress;
    // }
    

    function setMatPrb(uint8 boxIndex, uint8 materialIndex, uint16 Probability) public onlyManager{
        matProbability memory p;
        p.matIndex = materialIndex;
        p.probability = Probability;
        matPrb[boxIndex].push(p);
    }

    function resetMatPrb(uint8 boxIndex, uint16 setIndex, uint8 materialIndex, uint16 Probability) public onlyManager{
        matProbability memory p;
        p.matIndex = materialIndex;
        p.probability = Probability;
        matPrb[boxIndex][setIndex] = p;
    }

////////////// inquire function ///////////////

    function inquireNpcDrop(uint chaId) public view returns(uint[6]){
        if(isNpc(chaId)){
            bytes32 random = keccak256(abi.encodePacked(chaId, "Drop"));
            newMaterialsInterface newMat = newMaterialsInterface(addr("newMats"));
            return ([
                newMat.grade2Drop(0)[uint(random[0]).mod(newMat.grade2Drop(0).length)],
                newMat.grade2Drop(1)[uint(random[1]).mod(newMat.grade2Drop(1).length)],
                newMat.grade2Drop(2)[uint(random[2]).mod(newMat.grade2Drop(2).length)],
                newMat.grade2Drop(3)[uint(random[3]).mod(newMat.grade2Drop(3).length)],
                newMat.grade2Drop(4)[uint(random[4]).mod(newMat.grade2Drop(4).length)],
                newMat.grade2Drop(5)[uint(random[5]).mod(newMat.grade2Drop(5).length)]
                ]);
        }
        else{
            return([uint(0),uint(0),uint(0),uint(0),uint(0),uint(0)]);
        }
    }

    function isNpc(uint tokenId) public view returns(bool){  //確認角色是否為NPC
        return chaTokenInterface(addr("chaToken")).isNpc(tokenId);
    }

    function ownerOf(uint256 tokenId) public view returns (address) {
        return chaTokenInterface(addr("chaToken")).ownerOf(tokenId);
    }

    function isAlife(uint chaId) public view returns(bool){  //確認角色是否為活著狀態
        if(isNpc(chaId)){return true;}
        else{
            if(chaStatus[chaId].reviveTime <= now){
                return true;
            }
            else{
                return false;
            }
        }
    }

    function inquireOwnedTokensId(address player) public view returns(uint chaId) {  //查詢玩家擁有角色id(一個玩家只能有一隻)
        return chaTokenInterface(addr("chaToken")).inquireOwnedTokensId(player);
    }

    function inquireStatus(uint chaId) public view returns(uint16 location, uint64 reviveTime, bool inBattle){ //查詢函數
        if(isNpc(chaId) && !chaStatus[chaId].init){
            (location, reviveTime, inBattle) = (uint16(chaId%landCount), 0, false);
        }
        else{
            location = chaStatus[chaId].location;
            reviveTime = chaStatus[chaId].reviveTime;
            inBattle = chaStatus[chaId].inBattle;
        }
    }

    function inquirePair(uint chaId) public view returns(uint[5] opponent){
        opponent = pairWith[chaId];
    }

    function inquireRank(uint chaId) public view returns(uint16 level, uint exp, uint money){  //查詢函數
        return chaTokenInterface(addr("chaToken")).inquireRank(chaId);
    }

    function inquireAbility(uint chaId) public view returns(uint16 atk, uint16 def, uint16 hp){ //查詢原始能力值
        return chaTokenInterface(addr("chaToken")).inquireAbility(chaId);
    }

    function inquireInfo(uint chaId) public view returns(string characterName, uint8 avatar, uint8 career){ //查詢函數
        return chaTokenInterface(addr("chaToken")).inquireInfo(chaId);
    }

    function inquireBinding(uint chaId) public view returns(address){ //查詢函數
        return chaTokenInterface(addr("chaToken")).inquireBinding(chaId);
    }

    // function inquireSkill(uint chaId, uint8 term)public view returns(uint8 level, uint8 typ, uint8 index){
    //     return chaTokenInterface(addr("chaToken")).inquireSkill(chaId, term);
    // }

    function inquireNpcNames(uint chaId) public view returns(string FirstName, string MiddleName, string LastName, string NickName){
        return chaTokenInterface(addr("chaToken")).inquireNpcNames(chaId);
    }

    // function inquireFight(uint attackerId) public view returns(bool start, uint opponent, bool result){
    //     return (fightingRecord[attackerId].start, fightingRecord[attackerId].opponent, fightingRecord[attackerId].result);
    // }

    function inquireTotAbility(uint chaId) public view returns(uint16 atk, uint16 def, uint16 hp){ //查詢加裝備後能力值

        (uint16 _atk, uint16 _def, uint16 _hp) = inquireAbility(chaId);
        //uint256 length = equAmount();
        uint equid;

        for(uint8 i = 1; i <= equAmount() ; i++){ //beta版暫用

            //uint8 index = inquireOwnEquContract()[i];
            uint8 index = i;
            
            if(equ(index) != address(0)){
                equid = inquireEquipment(chaId, index);
                (,,int16 equAtk, int16 equDef, int16 equHp) = inquireEquAbility(equid, index);
                
                if(int16(_atk)+equAtk >= 0){
                    _atk = uint16(int16(_atk)+equAtk);
                }
                else{
                    _atk = 0;
                }

                if(int16(_def)+equDef >= 0){
                    _def = uint16(int16(_def)+equDef);
                }
                else{
                    _def = 0;
                }

                if(int16(_hp)+equHp >= 1){
                    _hp = uint16(int16(_hp)+equHp);
                }
                else{
                    _hp = 1;
                }
            }
        }
        (atk, def, hp) = (_atk, _def, _hp);
    }

    // function inquireNpcDrop(uint npcId) public view returns(uint[6] dropId){
    //     return chaTokenInterface(addr("chaToken")).inquireNpcDrop(npcId);
    // }

    function inquireDropValue(address _address, uint index) public view returns(uint dropId){
        return newMaterialsInterface(addr("newMats")).balanceOf(_address, index);
    }

    function inquireCoolTime(uint chaId) public view returns(uint64){
        return chaStatus[chaId].rewardCoolTime;
    }

//////////////Other function//////////////

    function() public payable{}

    function getRandom() public returns(bytes32){ //獲取亂數(從CharacterToken合約調用)
        return chaTokenInterface(addr("chaToken")).getRandom();
    }

    // function getViewRandom() public view returns(bytes32){ //獲取亂數(從CharacterToken合約調用,沒有改變seed)
    //     return chaTokenInterface(addr("chaToken")).getViewRandom();
    // }

    function createCharacter(string name, uint8 avatar, uint8 ethnicity) public payable{
        require(msg.value == 1 ether, "The payment value is wrong");
        chaTokenInterface(addr("chaToken")).createCharacter(msg.sender, name, avatar, ethnicity);
    }
    
    function upgrade(uint chaId) public{
        require(ownerOf(chaId) == msg.sender || ownerOf(chaId) == addr("chaToken"),
            "You can't use this character");
        chaTokenInterface(addr("chaToken")).upgrade(chaId);
    }

    function changelocation(uint chaId) public{
        chaStatus[chaId].location = uint16(getRandom())%1600;
    }

    function reward(uint chaId) public{
        require(ownerOf(chaId) == msg.sender || ownerOf(chaId) == addr("chaToken"),
            "You can't use this character");
        require(chaStatus[chaId].rewardCoolTime <= uint64(now), "Your cooling time is not end");
        chaTokenInterface(addr("chaToken")).reward(chaId);
        chaStatus[chaId].rewardCoolTime = uint64(now+86400);
        
    }

    function buyGC(uint chaId) public payable{
        require(ownerOf(chaId) == msg.sender || ownerOf(chaId) == addr("chaToken"),
            "You can't use this character");
        require(msg.value == 1 ether, "Value is not match");
        chaTokenInterface(addr("chaToken")).reward(chaId);
    }

    function buyMaterial(uint chaId, uint8 typ, uint8 amount) public{
        require(ownerOf(chaId) == msg.sender || ownerOf(chaId) == addr("chaToken"),
            "You can't use this character");
        //bytes32 random = getRandom();
        //uint8 index;

        chaTokenInterface(addr("chaToken")).payGC(chaId, uint(100).mul(amount)); //扣除該角色的GC

        // require(typ <= 4, "Type error");
        // require(amount <= 30, "Amount error");
        // uint8 i;
        // if(typ == 0){
        //     for (i = 0; i < amount; i++) {
        //         index = uint8(random[i]).mod(30);
        //         materialInterface(material).controlMint(typ, index, msg.sender, 1);
        //     }
        // }
        // else if(typ == 1){
        //     for (i = 0; i < amount; i++) {
        //         index = uint8(random[i]).mod(10);
        //         materialInterface(material).controlMint(typ, index, msg.sender, 1);
        //     }
        // }
        // else if(typ == 2){
        //     for (i = 0; i < amount; i++) {
        //         index = uint8(random[i]).mod(20);
        //         materialInterface(material).controlMint(typ, index, msg.sender, 1);
        //     }
        // }
        // else if(typ == 3){
        //     for (i = 0; i < amount; i++) {
        //         index = uint8(random[i]).mod(8);
        //         materialInterface(material).controlMint(typ, index, msg.sender, 1);
        //     }
        // }
        // else if(typ == 4){
        //     for (i = 0; i < amount; i++) {
        //         index = uint8(random[i]).mod(20);
        //         materialInterface(material).controlMint(typ, index, msg.sender, 1);
        //     }
        // }

        for (uint16 x = 0; x < amount; x++) {
            
            uint16 totProbability;
            for(uint16 i = 0; i < matPrb[typ].length; i++) {
                totProbability += matPrb[typ][i].probability;
            }
            uint16 lottery = uint16(getRandom()).mod(totProbability);

            uint8 getToken;
            uint16 currentNumber;
            for(uint16 j = 0; j < matPrb[typ].length; j++) {
                currentNumber += matPrb[typ][j].probability;
                if(currentNumber > lottery){
                    getToken = matPrb[typ][j].matIndex;
                    break;
                }
            }
            uint tokenId = uint(getToken).add(uint(typ).mul(100)).add(2000);
            newMaterialsInterface(addr("newMats")).mint(tokenId, msg.sender, 1);
            //增發素材給玩家
        }
    }

/////////////fighting function ////////////

    function randomInquireNpc(uint16 location) private returns(uint){  //找尋該位置npc ID
        bytes32 random = getRandom();
        uint idIndex = chaTokenInterface(addr("chaToken")).idIndex();
        uint newRadmom = (uint(random) % idIndex) / landCount;
        return (newRadmom * landCount + location);
        
        //需要搜尋出五隻npc
    }

    function randomPairNPC(uint chaId) private returns(uint){  //找尋該位置npc ID
        (uint16 myLoc,,) = inquireStatus(chaId);
        bytes32 random = getRandom();
        uint idIndex = chaTokenInterface(addr("chaToken")).idIndex();
        uint newRadmom = (uint(random) % idIndex) / landCount;
        return (newRadmom * landCount + myLoc);
        
        //需要搜尋出五隻npc
    }

    function pair(uint attacker) public {  //玩家配對npc
        require(ownerOf(attacker) == msg.sender || ownerOf(attacker) == addr("chaToken"),
            "You can't use this character");
        for(uint i = 0;i<5;i++){
            pairWith[attacker][i] = randomPairNPC(attacker);
        }
    }

    function startBattle(uint attacker, uint8 opponentIndex) public{ //玩家調用使玩家角色攻擊
        require(ownerOf(attacker) == msg.sender || ownerOf(attacker) == address(this),
            "You can't use this character");

        uint opponent = pairWith[attacker][opponentIndex]; //防禦者(被打的npc)
        require(!chaStatus[attacker].inBattle,"You are in battle");
        require(!chaStatus[attacker].inInstance,"You are in inInstance");

        require(attacker != 0,"Attacker ID is 0");
        require(opponent != 0,"Defender ID is 0");

        if(!isNpc(opponent)){
            chaStatus[opponent].inBattle = true; //配對到的npc進入戰鬥狀態
        }
        
        // fightingRecord[attacker].start = true; //該戰鬥顯示為開始
        // fightingRecord[attacker].opponent = opponent; //紀錄敵人id

        chaStatus[attacker].inBattle = true;

        pairWith[attacker] = [0,0,0,0,0];

        battleInterface(addr("battle")).ready(attacker, opponent);
    }

    function startInstance(uint attacker, uint16 level) public{ //玩家調用使玩家角色攻擊
        require(ownerOf(attacker) == msg.sender || ownerOf(attacker) == address(this),
            "You can't use this character");
        require(attacker != 0,"Attacker ID is 0");
        require(!chaStatus[attacker].inBattle,"You are in battle");
        require(!chaStatus[attacker].inInstance,"You are in inInstance");
        
        if(level == 30){
            chaTokenInterface(addr("chaToken")).payGC(attacker, 5000);
        }
        else if(level == 50){
            chaTokenInterface(addr("chaToken")).payGC(attacker, 25000);
        }
        else if(level == 80){
            chaTokenInterface(addr("chaToken")).payGC(attacker, 50000);
        }
        else{
            revert("Level is not correct");
        }

        chaStatus[attacker].inInstance = true;

        //emit Fight(fightingId, attacker, opponent);

        InstanceInterface(addr("instance")).ready(attacker, level);
    }

    function endFight(uint attacker, uint opponent, bool result) public onlyBattle{ //回傳戰鬥結果
        
        (uint16 opponentLevel,,) = inquireRank(opponent);
        (uint16 attackerLevel,,) = inquireRank(attacker);
        
        chaStatus[attacker].inBattle = false;
        if(!isNpc(opponent)){
            chaStatus[opponent].inBattle = false;
        }

        if(result){ //攻擊者獲勝
            uint value;
            uint dropId;

            uint8 random = uint8(getRandom()).mod(100);
            random = random.add(uint8(opponentLevel).div(2));  //Random掉落物數值

            uint[6] memory dropIndex = inquireNpcDrop(opponent);

            if(random <= 50){
                dropId = dropIndex[0];   //Random掉落物1-50數值獲得NPC掉落物Grande-0
            }
            else if(50 < random && random <= 80){
                dropId = dropIndex[1];   //Random掉落物51-80數值獲得NPC掉落物Grande-1
            }
            else if(80 < random && random <= 92){
                dropId = dropIndex[2];   //Random掉落物81-92數值獲得NPC掉落物Grande-2
            }
            else if(92 < random && random <= 97){
                dropId = dropIndex[3];   //Random掉落物93-97數值獲得NPC掉落物Grande-3
            }
            else if(97 < random && random <= 99){
                dropId = dropIndex[4];   //Random掉落物98-99數值獲得NPC掉落物Grande-4
            }
            else{
                dropId = dropIndex[5];   //Random掉落物100數值獲得NPC掉落物Grande-5
            }
            
            address _to = ownerOf(attacker);
            //uint newmatId = dropId.add(7000);
            newMaterialsInterface(addr("newMats")).mint(dropId, _to, 1);

            addExp(attacker, uint(opponentLevel.mul(100)));
            addExp(opponent, uint(attackerLevel.mul(10)));
            
            (,,uint opMoney) = inquireRank(opponent);
            value = opMoney.div(10);
            emit fightResult(attacker, opponentLevel.mul(100), int(value));
            transferMoney(opponent, attacker, value);
        }
        else{   //攻擊者失敗
        
            addExp(opponent, uint(attackerLevel.mul(100)));
            addExp(attacker, uint(opponentLevel.mul(10)));

            (,,uint atkMoney) = inquireRank(attacker);
            value = atkMoney.div(10);
            emit fightResult(attacker, opponentLevel.mul(10), -int(value));
            transferMoney(attacker, opponent, value);
        }
    }

    function endInstance(uint attacker) public only("instance"){ //回傳戰鬥結果
        
        chaStatus[attacker].inInstance = false;
    }

    ////////////  private function ///////////////

    function addExp(uint chaId, uint _exp) private{
        chaTokenInterface(addr("chaToken")).addExp(chaId, _exp);
    }

    function addMoney(uint chaId, uint _money) private{
        chaTokenInterface(addr("chaToken")).addMoney(chaId, _money);
    }

    function transferMoney(uint from, uint to, uint value) private{
        chaTokenInterface(addr("chaToken")).transferMoney(from, to, value);
    }

    //////////// Equiment function ///////////////


    function buyEquiment(uint chaId, uint8 equType, uint equID) public{
        require(chaTokenInterface(addr("chaToken")).ownerOf(chaId) == msg.sender||
            chaTokenInterface(addr("chaToken")).ownerOf(chaId) == addr("chaToken"));
        //uint chaId = chaTokenInterface(addr("chaToken")).inquireOwnedTokensId(msg.sender);
        address equAddress = equ(equType);
        address equOwner = IERC721(equAddress).ownerOf(equID);
        require(equOwner == address(this),"It can't buy");

        uint equprice = equPrice[equType][equID];
        
        chaTokenInterface(addr("chaToken")).payGC(chaId, equprice);

        equInterface(equAddress).safeTransferFrom(address(this), msg.sender, equID); //把裝備給玩家

        (bool isEqu, ) = equInterface(equAddress).inquireStatus(equID);
        require(!isEqu,"已綁定裝備");
    }

    function changeEquipment(uint chaId, uint8 equType, uint equId) public{
        require(chaId == inquireOwnedTokensId(msg.sender),"");
        chaTokenInterface(addr("chaToken")).changeEquipment(msg.sender, chaId, equType, equId);
    }

    // function inquireOwnEquContract() public view returns(uint8[]){  //查詢擁有的裝備合約
    //     return chaTokenInterface(addr("chaToken")).inquireOwnEquContract();
    // }

    // function inquireEquContract(uint8 equType) public view returns(address){  //查詢欄位對應的裝備合約
    //     return chaTokenInterface(addr("chaToken")).inquireEquContract(equType);
    // }

    function inquireEquipment(uint chaId, uint8 _equType) public view returns(uint equID){ //查詢角色身上所穿裝備
        return chaTokenInterface(addr("chaToken")).inquireEquipment(chaId, _equType);
    }

    function inquireEquInfo(uint equId, uint8 equtyp) public view returns(string name, uint8 equiptType){
        address equAdr = equ(equtyp);
        return equInterface(equAdr).inquireInfo(equId);
    }

    function inquireEquStatus(uint equId, uint8 equtyp) public view returns(bool isEquipped, uint whoWear){
        address equAdr = equ(equtyp);
        return equInterface(equAdr).inquireStatus(equId);
    }

    function inquireEquAbility(uint equId, uint8 equtyp) public view returns(uint8 rarity, uint8 star, int16 atk, int16 def, int16 hp){
        address equAdr = equ(equtyp);
        return equInterface(equAdr).inquireAbility(equId);
    }

    function inquireEquOwnerOf(uint equId, uint8 equtyp) public view returns(address owner){
        address equAdr = equ(equtyp);
        return equInterface(equAdr).ownerOf(equId);
    }

    function inquireOwnEqu(address _address, uint8 equtyp) public view returns(uint[]){
        address equAdr = equ(equtyp);
        return equInterface(equAdr).inquireOwnEqu(_address);
    }

}