pragma solidity >= 0.4.25;

import "./libraries/math.sol";
import "./libraries/OMD.sol";
import "./ERC721.sol";

interface chaExInterface{
    function isNpc(uint tokenId) external view returns(bool);
    function ownerOf(uint256 tokenId) external view returns (address);
    function isAlife(uint chaId) external view returns(bool);
    function inquireOwnedTokensId(address player) external view returns(uint chaId);
    function inquireStatus(uint chaId) external view returns(uint16 location, uint[5] opponent, uint64 reviveTime, bool inBattle);
    function inquirePair(uint chaId) external view returns(uint[5] opponent);
    function inquireRank(uint chaId) external view returns(uint16 level, uint exp, uint money);
    function inquireAbility(uint chaId) external view returns(uint16 atk, uint16 def, uint16 hp);
    function inquireInfo(uint chaId) external view returns(string characterName, uint8 avatar, uint8 career);
    function inquireBinding(uint chaId) external view returns(address);
    // function inquireSkill(uint chaId, uint8 term)external view returns(uint8 level, uint8 typ, uint8 index);
    function inquireNpcNames(uint chaId) external view returns(string FirstName, string LastName, string NickName);
    function inquireFight(uint fightId) external view returns(bool start, uint attacker , uint defender, bool result);
    function inquireTotAbility(uint chaId) external view returns(uint16 atk, uint16 def, uint16 hp);
    function endFight(uint attacker, uint opponent, bool result) external;
    //接上角色外部合約
}

interface chaTokenInterface{
    function endFight(uint attacker, uint opponent, bool result) external;
    function ownerOf(uint256 tokenId) external view returns (address);
    //接上角色Token合約
}

contract battle is setOperator{
    using SafeMath for uint256;
    using SafeMath16 for uint16;
    
    // address public chaEx;
    // address public chaToken;
    // address skill;
    
    uint randomSeed;

    //mapping (uint => fighting) private fightingStatus; //戰鬥狀態
    //mapping (uint => uint) private haveFighting; //角色對應到的戰鬥編號
    mapping (uint => fighting) private fightingStatus; //戰鬥狀態(攻擊者 => 狀態)

    event Attacking(uint indexed attacker, uint opponent,uint8 _type, uint damage);
    event Attacked(uint indexed opponent, uint attacker,uint8 _type, uint damage);
    event Attacking_miss(uint indexed attacker, uint opponent,uint8 _type);
    event Attacked_miss(uint indexed opponent, uint attacker,uint8 _type);
    event Blood(uint indexed attacker, uint value);
    event EndFight(uint indexed attacker, uint opponent, bool result);
    
    constructor () public {
        randomSeed = uint((keccak256(abi.encodePacked(now))));
    }

    struct status{
        //uint cha; //角色id
        //uint fightingID;
        //uint opponent;
        
        uint16 hpLimit; //血量上限
        uint16 hp;  //血量
        uint16 atk; //攻擊
        uint16 def; //防禦
        uint16 critical; //爆擊
        uint16 speed; //速度
        uint16 luck; //運氣
        uint16 hit; //命中率
        uint8 cure_cnt; //治癒次數
        bool isAttack; //能否攻擊
    }

    struct fighting {
        //bool start; //是否開始
        status attacker; //攻擊者
        status opponent; //敵人
        uint opponentId; //敵人Id
        //bool result; //結果,true為攻擊者獲勝
    }

    // modifier onlychaEx{
    //     require(msg.sender == chaEx, "You are not npc Contract");
    //     _;
    // }

    // function setChaEx(address newAddress) public onlyManager{
    //     chaEx = newAddress;
    // }
    // function setchaToken(address newAddress) public onlyManager{
    //     chaToken = newAddress;
    // }
    // function setSkill(address newAddress) public onlyManager{
    //     skill = newAddress;
    // }

    function ownerOf(uint256 tokenId) public view returns (address) {
        return chaTokenInterface(addr("chaToken")).ownerOf(tokenId);
    }

//////////////////inquire function////////////////

    function inquireSelfStatus(uint attacker) public view returns (uint16 hpLimit, uint16 hp, uint16 atk, uint16 def, uint16 critical,
        uint16 speed, uint16 luck,uint16 hit){

        hpLimit = fightingStatus[attacker].attacker.hpLimit;
        hp = fightingStatus[attacker].attacker.hp;
        atk = fightingStatus[attacker].attacker.atk;
        def = fightingStatus[attacker].attacker.def;
        critical = fightingStatus[attacker].attacker.critical;
        speed = fightingStatus[attacker].attacker.speed;
        luck = fightingStatus[attacker].attacker.luck;
        hit = fightingStatus[attacker].attacker.hit;
        
    }
 
    function inquireOpponentStatus(uint attacker) public view returns (uint16 hpLimit, uint16 hp, uint16 atk, uint16 def, uint16 critical,
        uint16 speed, uint16 luck,uint16 hit){
        hpLimit = fightingStatus[attacker].opponent.hpLimit;
        hp = fightingStatus[attacker].opponent.hp;
        atk = fightingStatus[attacker].opponent.atk;
        def = fightingStatus[attacker].opponent.def;
        critical = fightingStatus[attacker].opponent.critical;
        speed = fightingStatus[attacker].opponent.speed;
        luck = fightingStatus[attacker].opponent.luck;
        hit = fightingStatus[attacker].opponent.hit;
    }

    function inquireOpponentId(uint attacker) public view returns (uint OppId){
        OppId = fightingStatus[attacker].opponentId;
    }

/////////////////////////////////////////////////

    function getRandom() public returns(bytes32){
        randomSeed += now;
        return keccak256(abi.encodePacked(block.difficulty, randomSeed));
    }

    function ready(uint attacker, uint opponent) public only("chaEx"){ //初始化戰鬥

        (uint16 attackerAtk, uint16 attackerDef, uint16 attackerHp) = chaExInterface(addr("chaEx")).inquireTotAbility(attacker);
        
        fightingStatus[attacker].attacker.hpLimit = attackerHp;
        fightingStatus[attacker].attacker.hp = attackerHp;
        fightingStatus[attacker].attacker.atk = attackerAtk;
        fightingStatus[attacker].attacker.def = attackerDef;
        fightingStatus[attacker].attacker.critical = 20;
        fightingStatus[attacker].attacker.speed = 10;
        fightingStatus[attacker].attacker.luck = 10;
        fightingStatus[attacker].attacker.isAttack = true;
        fightingStatus[attacker].attacker.hit = 100;
        fightingStatus[attacker].attacker.cure_cnt = 3;

        fightingStatus[attacker].opponentId = opponent;
        (uint16 opponentAtk, uint16 opponentDef, uint16 opponentHp) = chaExInterface(addr("chaEx")).inquireTotAbility(opponent);

        fightingStatus[attacker].opponent.hpLimit = opponentHp;
        fightingStatus[attacker].opponent.hp = opponentHp;
        fightingStatus[attacker].opponent.atk = opponentAtk;
        fightingStatus[attacker].opponent.def = opponentDef;
        fightingStatus[attacker].opponent.critical = 20;
        fightingStatus[attacker].opponent.speed = 10;
        fightingStatus[attacker].opponent.luck = 10;
        fightingStatus[attacker].opponent.isAttack = true;
        fightingStatus[attacker].opponent.hit = 100;
    }
    
    function attack(uint attacker, uint8 _type) public {                     //玩家選擇攻擊方式
        require(ownerOf(attacker) == msg.sender || ownerOf(attacker) == addr("chaToken"),
            "You can't use this character");

        require(fightingStatus[attacker].opponentId != 0, "Your character not in battle");
        
        uint16 attackerAtk;
        uint16 opponentDef;
        if(fightingStatus[attacker].attacker.isAttack){
            if(_type == 0){
                (attackerAtk, opponentDef) = attackStandard(attacker,0);    //0為玩家呼叫 ，1為NPC呼叫
            }else if(_type == 1){
                (attackerAtk, opponentDef) = attackHead(attacker,0);
            }else if(_type == 2){
                (attackerAtk, opponentDef) = attackTorso(attacker,0);
            }else if(_type == 3){
                (attackerAtk, opponentDef) = attackHands(attacker,0);
            }else if(_type == 4){
                (attackerAtk, opponentDef) = attackLegs(attacker,0);
            }else if(_type == 5){
                (attackerAtk, opponentDef) = attackEyes(attacker,0);
            }else if(_type == 6){
                (attackerAtk, opponentDef) = attackHeart(attacker,0);
            }
        }
        
        
        uint opponent = fightingStatus[attacker].opponentId;
        uint16 opponentsubHp;
        
        if(fightingStatus[attacker].attacker.isAttack){                          //玩家狀態為可攻擊時
            if(opponentDef >= attackerAtk){
                opponentsubHp = 1;
            }
            else{
                opponentsubHp = attackerAtk.sub(opponentDef);                   //扣敵方多少血量
            }
     
            if(opponentsubHp >= fightingStatus[attacker].opponent.hp){                  
                emit Attacking(attacker, opponent, _type, fightingStatus[attacker].opponent.hp);
                fightingStatus[attacker].opponent.hp = 0; //敵人掛掉了
                emit EndFight(attacker, opponent, true);
                chaExInterface(addr("chaEx")).endFight(attacker, opponent, true);
                //chaExInterface(chaEx).endFight(attacker, opponent);
                fightingStatus[attacker].opponentId = 0; //結束戰鬥,將對手清空
                return;                                  //敵方死亡跳結束戰鬥                   
            }
            else{
                fightingStatus[attacker].opponent.hp =
                fightingStatus[attacker].opponent.hp.sub(opponentsubHp); //減掉敵人HP
                emit Attacking(attacker, opponent, _type, opponentsubHp);
            }
        }else{
            emit Attacking_miss(attacker, opponent, _type);
            fightingStatus[attacker].attacker.isAttack = true;
        }
        
        uint16 attackersubHp;
        uint16 opponentAtk;
        uint16 attackerDef;
         
        
        uint8 random =  uint8(getRandom()) % 100+1;
            
            
            if(random > 0 && random <71){                                 //NPC隨機使用某種攻擊
                (opponentAtk, attackerDef) = attackStandard(attacker,1);
                _type = 0; 
            }else if(random > 70 && random <76){
                (opponentAtk, attackerDef) = attackHead(attacker,1);
                _type = 1;
            }else if(random > 75 && random <81){
                (opponentAtk, attackerDef) = attackTorso(attacker,1);
                _type = 2;
            }else if(random > 80 && random <86){
                (opponentAtk, attackerDef) = attackHands(attacker,1);
                _type = 3;
            }else if(random > 85 && random <91){
                (opponentAtk, attackerDef) = attackLegs(attacker,1);
                _type = 4; 
            }else if(random > 90 && random <96){
                (opponentAtk, attackerDef) = attackEyes(attacker,1);
                _type = 5;
            }else if(random > 95 && random <101){
                (opponentAtk, attackerDef) = attackHeart(attacker,1);
                _type = 6;
            }
        
        if(fightingStatus[attacker].opponent.isAttack){             //NPC狀態為可攻擊時
            if(attackerDef >= opponentAtk){
                attackersubHp = 1;
            }
            else{
                attackersubHp = opponentAtk.sub(attackerDef);
            }
     
            if(attackersubHp >= fightingStatus[attacker].attacker.hp){
                emit Attacked(opponent, attacker, _type, fightingStatus[attacker].attacker.hp);
                fightingStatus[attacker].attacker.hp = 0;  //攻擊者掛掉了
                emit EndFight(attacker, opponent, false);
                chaExInterface(addr("chaEx")).endFight(attacker, opponent, false);
                //chaExInterface(chaEx).endFight(attacker, opponent);
                fightingStatus[attacker].opponentId = 0; //結束戰鬥,將對手清空
            }
            else{
                fightingStatus[attacker].attacker.hp =
                    fightingStatus[attacker].attacker.hp.sub(attackersubHp); //減掉攻擊者HP
                emit Attacked(opponent, attacker, _type, attackersubHp);
            }
        
        }else{
            emit Attacked_miss(attacker, opponent, _type);
            fightingStatus[attacker].opponent.isAttack = true;
        }

    }

    function attackStandard(uint attacker,uint8 whoscall) private  returns(uint16 attackerAtk,uint16 opponentDef){         //不瞄準部位 
        uint8 random =  uint8(getRandom()) % 100;
     
        if(whoscall == 0){                                              //玩家調用
            if(random < fightingStatus[attacker].attacker.hit){         //有命中
                attackerAtk = fightingStatus[attacker].attacker.atk;
                opponentDef = fightingStatus[attacker].opponent.def.div(2);
            }else{
                fightingStatus[attacker].attacker.isAttack = false;
            }

        }else{ 
            if(random < fightingStatus[attacker].opponent.hit){         //有命中
                attackerAtk = fightingStatus[attacker].opponent.atk;
                opponentDef = fightingStatus[attacker].attacker.def.div(2);
            }else{
                fightingStatus[attacker].opponent.isAttack = false;
            }
        } 
    }
    
    function attackHead(uint attacker,uint8 whoscall) private returns(uint16 attackerAtk,uint16 opponentDef){              //攻擊頭部 
        
        bytes32 ranSeed = getRandom();
        uint8 random1 =  uint8(keccak256(abi.encodePacked(now,uint(ranSeed[5])))) % 100 + 1;
        uint8 random2 =  uint8(keccak256(abi.encodePacked(now,uint(ranSeed[6])))) % 100 ;
        
        if(whoscall == 0){                                           //玩家調用                 
            if(random1 > 90 && random2 < fightingStatus[attacker].attacker.hit){
                attackerAtk = fightingStatus[attacker].attacker.atk;
                opponentDef = fightingStatus[attacker].opponent.def.div(2);
                fightingStatus[attacker].opponent.isAttack = false;
            }else{
                fightingStatus[attacker].attacker.isAttack = false;
            }
       
        }else{
            if(random1 > 90 && random2 < fightingStatus[attacker].opponent.hit){
                attackerAtk = fightingStatus[attacker].opponent.atk;
                opponentDef = fightingStatus[attacker].attacker.def.div(2);
                fightingStatus[attacker].attacker.isAttack = false;
            }else{
                fightingStatus[attacker].opponent.isAttack = false;
            }
            
        }
    }
    
    function attackTorso(uint attacker,uint8 whoscall) private returns(uint16 attackerAtk,uint16 opponentDef){              //攻擊上身 
    
        bytes32 ranSeed = getRandom();
        uint8 random1 =  uint8(keccak256(abi.encodePacked(now,uint(ranSeed[7])))) % 100 + 1;
        uint8 random2 =  uint8(keccak256(abi.encodePacked(now,uint(ranSeed[8])))) % 100 ;
        
        if(whoscall == 0){ 
            if(random1 > 30 && random2 < fightingStatus[attacker].attacker.hit){
                attackerAtk = fightingStatus[attacker].attacker.atk;
                opponentDef = fightingStatus[attacker].opponent.def.mul(9).div(10);
            }else{
                fightingStatus[attacker].attacker.isAttack = false;
            }
        }else{
             if(random1 > 30 && random2 < fightingStatus[attacker].opponent.hit){
                attackerAtk = fightingStatus[attacker].opponent.atk;
                opponentDef = fightingStatus[attacker].attacker.def.mul(9).div(10);
             }else{
                fightingStatus[attacker].opponent.isAttack = false;
             }
        }
    }
    
    function attackHands(uint attacker,uint8 whoscall) private returns(uint16 attackerAtk,uint16 opponentDef){              //攻擊手部
    
        bytes32 ranSeed = getRandom();
        uint8 random1 =  uint8(keccak256(abi.encodePacked(now,uint(ranSeed[9])))) % 100 + 1;
        uint8 random2 =  uint8(keccak256(abi.encodePacked(now,uint(ranSeed[10])))) % 100 ;
 
        if(whoscall == 0){ 
            if(random1 > 50 && random2 < fightingStatus[attacker].attacker.hit){
                attackerAtk = fightingStatus[attacker].attacker.atk;
                opponentDef = fightingStatus[attacker].opponent.def.mul(8).div(10);
                fightingStatus[attacker].opponent.atk = fightingStatus[attacker].opponent.atk.sub(fightingStatus[attacker].opponent.atk.mul(3).div(100));
                fightingStatus[attacker].opponent.def = fightingStatus[attacker].opponent.def.sub(fightingStatus[attacker].opponent.def.mul(3).div(100));
            }else{
                fightingStatus[attacker].attacker.isAttack = false;    
            }
        }else{
            if(random1 > 50 && random2 < fightingStatus[attacker].opponent.hit){
                attackerAtk = fightingStatus[attacker].opponent.atk;
                opponentDef = fightingStatus[attacker].attacker.def.mul(8).div(10);
                fightingStatus[attacker].attacker.atk = fightingStatus[attacker].attacker.atk.sub(fightingStatus[attacker].attacker.atk.mul(3).div(100));
                fightingStatus[attacker].attacker.def = fightingStatus[attacker].attacker.def.sub(fightingStatus[attacker].attacker.def.mul(3).div(100));
            }else{
                fightingStatus[attacker].opponent.isAttack = false;    
            }
        }
    }
    
    function attackLegs(uint attacker,uint8 whoscall) private returns(uint16 attackerAtk,uint16 opponentDef){              //攻擊腿部 
        bytes32 ranSeed = getRandom();
        uint8 random1 =  uint8(keccak256(abi.encodePacked(now,uint(ranSeed[11])))) % 100 + 1;
        uint8 random2 =  uint8(keccak256(abi.encodePacked(now,uint(ranSeed[12])))) % 100 ;
 
        if(whoscall == 0){ 
            if(random1 > 50 && random2 < fightingStatus[attacker].attacker.hit){
                attackerAtk = fightingStatus[attacker].attacker.atk;
                opponentDef = fightingStatus[attacker].opponent.def.mul(8).div(10);
                fightingStatus[attacker].opponent.def = fightingStatus[attacker].opponent.def.sub(fightingStatus[attacker].opponent.def.mul(5).div(100));
            }else{
                fightingStatus[attacker].attacker.isAttack = false;    
            }
        }else{
            if(random1 > 50 && random2 < fightingStatus[attacker].opponent.hit){
                attackerAtk = fightingStatus[attacker].opponent.atk;
                opponentDef = fightingStatus[attacker].attacker.def.mul(8).div(10);
                fightingStatus[attacker].attacker.def = fightingStatus[attacker].attacker.def.sub(fightingStatus[attacker].attacker.def.mul(5).div(100));
            }else{
                fightingStatus[attacker].opponent.isAttack = false;    
            }
        }
    }
    
    function attackEyes(uint attacker,uint8 whoscall) private returns(uint16 attackerAtk,uint16 opponentDef){              //攻擊眼部 
        bytes32 ranSeed = getRandom();
        uint8 random1 =  uint8(keccak256(abi.encodePacked(now,uint(ranSeed[13])))) % 100 + 1;
        uint8 random2 =  uint8(keccak256(abi.encodePacked(now,uint(ranSeed[14])))) % 100 ;

        if(whoscall == 0){ 
            if(random1 > 95 && random2 < fightingStatus[attacker].attacker.hit){  
                attackerAtk = fightingStatus[attacker].attacker.atk.add(fightingStatus[attacker].attacker.atk.div(2));
                opponentDef = fightingStatus[attacker].opponent.def.mul(4).div(10); 
                fightingStatus[attacker].opponent.hit = fightingStatus[attacker].opponent.hit.div(2);
                fightingStatus[attacker].opponent.isAttack = false;
            }else{
                fightingStatus[attacker].attacker.isAttack = false;    
            }
            
        }else{
            if(random1 > 95 && random2 < fightingStatus[attacker].opponent.hit){ 
                attackerAtk = fightingStatus[attacker].opponent.atk.add(fightingStatus[attacker].opponent.atk.div(2));
                opponentDef = fightingStatus[attacker].attacker.def.mul(4).div(10);
                fightingStatus[attacker].attacker.hit = fightingStatus[attacker].attacker.hit.div(2);
                fightingStatus[attacker].attacker.isAttack = false;     
            }else{
                fightingStatus[attacker].opponent.isAttack = false;     
            }
        }
    }
    
    function attackHeart(uint attacker,uint8 whoscall) private returns(uint16 attackerAtk,uint16 opponentDef){              //攻擊頭部 
        bytes32 ranSeed = getRandom();
        uint8 random1 =  uint8(keccak256(abi.encodePacked(now,uint(ranSeed[15])))) % 100 + 1;
        uint8 random2 =  uint8(keccak256(abi.encodePacked(now,uint(ranSeed[16])))) % 100 ;
        
        if(whoscall == 0){
            if(random1 > 99 && random2 < fightingStatus[attacker].attacker.hit){ 
                attackerAtk = fightingStatus[attacker].attacker.atk.mul(3);
                opponentDef = fightingStatus[attacker].opponent.def.div(10);
                fightingStatus[attacker].opponent.atk = fightingStatus[attacker].opponent.atk.div(2);
                fightingStatus[attacker].opponent.isAttack = false;    
            }else{
                fightingStatus[attacker].attacker.isAttack = false;    
                
            }
        }else{
             if(random1 > 99 && random2 < fightingStatus[attacker].opponent.hit){
                attackerAtk = fightingStatus[attacker].opponent.atk.mul(3);
                opponentDef = fightingStatus[attacker].attacker.def.div(10);
                fightingStatus[attacker].attacker.atk = fightingStatus[attacker].attacker.atk.div(2);
                fightingStatus[attacker].attacker.isAttack = false;    
             }else{
                fightingStatus[attacker].opponent.isAttack = false; 
                 
             }
        }
    }
    /////////////////////////////
    
    function runAway(uint attacker) public{
        require(ownerOf(attacker) == msg.sender || ownerOf(attacker) == addr("chaToken"),
            "You can't use this character");
            
        uint opponent = fightingStatus[attacker].opponentId;
        require(opponent != 0, "Your character not in battle");
        //調用token合約結算

        emit EndFight(attacker, opponent, false);
        chaExInterface(addr("chaEx")).endFight(attacker, opponent, false);
        //chaTokenInterface(chaToken).endFight(attacker, opponent, false);
        fightingStatus[attacker].opponentId = 0; //結束戰鬥,將對手清空
        
    }

    function blood(uint attacker) public{
        require(ownerOf(attacker) == msg.sender || ownerOf(attacker) == addr("chaToken"),
            "You can't use this character");

        require(fightingStatus[attacker].opponentId != 0, "Your character not in battle");
        require(fightingStatus[attacker].attacker.cure_cnt != 0 );
        
        uint16 bloodHp = fightingStatus[attacker].attacker.hpLimit.mul(3).div(10);

        if(fightingStatus[attacker].attacker.hp.add(bloodHp) >= fightingStatus[attacker].attacker.hpLimit){
            fightingStatus[attacker].attacker.hp = fightingStatus[attacker].attacker.hpLimit;
        }
        else{
            fightingStatus[attacker].attacker.hp = fightingStatus[attacker].attacker.hp.add(bloodHp);
        }
        fightingStatus[attacker].attacker.cure_cnt--;
        
    }

    function useSkill(uint attacker, uint16 skill) public{
        
    }

}
