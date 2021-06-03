pragma solidity >= 0.4.25;

import "./libraries/math.sol";
import "./libraries/OMD.sol";

interface master{
    function inquire_location(address _address) external view returns(uint16, uint16);
    function inquire_slave_address(uint16 _slave) external view returns(address);
    function inquire_land_info(uint16 _city, uint16 _id) external view returns(uint8,uint8,uint8,uint8,uint8,uint8,uint8,uint8,uint8,uint8);
    function domain_attribute(uint16 _city,uint16 _id, uint8 _index) external;
    function inquire_tot_attribute(uint16 _slave, uint16 _domain) external view returns(uint8[5]);
     
    function inquire_owner(uint16 _city, uint16 id) external view returns(address);
    
}

interface newMaterialsInterface{
    function burn(uint256 tokenIndex, address from, uint256 _amount) external;
}

// interface material{
//     function control_burn(uint8 boxIndex, uint8 materialIndex, address target, uint256 amount) external;
// }

// interface hunter_mat1155{
//     function burn(uint materialIndex, address _addr, uint _value) external;
// }

interface EquipDemo{
    function createEquipment(address _to,string _name, uint16 _id,uint8 _amount,uint8 _level) external;
}

 
interface chaTokenInerface {
    // function inquireSkill(uint chaId, uint8 term) external view returns(uint8 level, uint8 typ, uint8 index);
    function inquireOwnedTokensId(address player) external view returns(uint id);
}



// contract owned{

//     address public manager;

//     constructor() public{
//         manager = msg.sender;
//     }

//     modifier onlyManager{
//         require(msg.sender == manager);
//         _;
//     }

//     function transferownership(address _new_manager) public onlyManager {
//         manager = _new_manager;
//     }

// }

contract mix is setOperator{  
    
    event mix_result(address indexed player, bool result, uint16 rate); 

    // address public arina_address;
    // address public master_address;
    // // address public material_address;  //素材主合約
    // // address public ERC1155_address;
    // address public addr("newMats");
    // address public chaTokenContract;

    struct equ_info{
        string equipt_name;
        uint8[3] boxIndex;
        uint8[3] materialIndex;
        uint[3] amount;
        uint8 rarity;
        uint8 equ_type;
    }
    
    struct equ_ability{
        int16 atk_max;
        int16 atk_min; 
        int16 def_max;
        int16 def_min;
        int16 hp_max;
        int16 hp_min;
    }
 
    //uint8 i;//給for迴圈給for迴圈迴圈當初使值用
    
    mapping(uint => equ_info) internal weapons_info;
    mapping(uint => equ_ability) internal weapons_ability;
    mapping(uint => equ_info) internal armors_info;
    mapping(uint => equ_ability) internal armors_ability;
    mapping(uint => equ_info) internal rings_info;
    mapping(uint => equ_ability) internal rings_ability;
    //mapping (uint8 => address) public equContract; //儲存裝備合約

    
    uint16[5] paramA;
    uint16[5] paramB; 
    uint16[5] paramC; 
    uint16[5] paramD;
    uint16[5] paramE; 
    uint16[5] paramF;

    
    constructor() public{
        paramA=[50,30,10,5,1];
        paramB=[100,50,30,10,5]; 
        paramC=[200,100,50,30,10];
        paramD=[300,150,100,50,30];
        paramE=[400,200,150,100,50];
        paramF=[500,300,200,150,100];
    } 
     
    using SafeMath for uint256;
    using SafeMath16 for uint16;
    using SafeMath8 for uint8;
    
    ///////////////////管理function/////////////////////

    // function changechaTokenContract(address newAddress) public onlyManager{
    //     chaTokenContract = newAddress;
    // }
    
    // function set_material_contract(address _material_address) public onlyManager{
    //     material_address = _material_address;
    // }

    
    // function set_master(address _new_master) public onlyManager {
    //     master_address = _new_master;
    // }
    
    // function set_ERC1155_address(address _new_master) public onlyManager {
    //     ERC1155_address = _new_master;
    // }

    // function setNewMaterials(address newAddress) public onlyManager{
    //     addr("newMats") = newAddress;
    // }

    
    // function setequContract(uint8 equType, address newAddress) public onlyManager{ //car => 0 item1 => 1 ...
    //     equContract[equType] = newAddress;  //沒有合約地址就沒有裝備欄位
    // }

    // function delEquipmentField(uint8 equType) public onlyManager{ //car => 0 item1 => 1 ...
    //     equContract[equType] = address(0);  //沒有合約地址就沒有裝備欄位
    // }

    
    function set_weapons(uint16 weapons_id,string _name, uint8[3] _boxIndex,uint8[3] _materialIndex, uint[3] _amount,uint8 _rarity,uint8 _equ_type
                         ,int16[2] _atkLimit, int16[2] _defLimit ,int16[2] _hpLimit) public onlyManager{
    //設置合成武器資訊    

        weapons_info[weapons_id].equipt_name = _name;
        
        for(uint8 i = 0 ;i < _boxIndex.length;i++){
            weapons_info[weapons_id].boxIndex[i] = _boxIndex[i];
            weapons_info[weapons_id].materialIndex[i] = _materialIndex[i];
            weapons_info[weapons_id].amount[i] = _amount[i];
        }
        
        
        weapons_info[weapons_id].rarity = _rarity;
        weapons_info[weapons_id].equ_type = _equ_type;
         
        weapons_ability[weapons_id].atk_max = _atkLimit[0];
        weapons_ability[weapons_id].atk_min = _atkLimit[1];
        weapons_ability[weapons_id].def_max = _defLimit[0];
        weapons_ability[weapons_id].def_min = _defLimit[1];
        weapons_ability[weapons_id].hp_max = _hpLimit[0];
        weapons_ability[weapons_id].hp_min = _hpLimit[1];
    }
    
    
    function set_armors(uint16 armors_id,string _name, uint8[3] _boxIndex,uint8[3] _materialIndex, uint[3] _amount,uint8 _rarity,uint8 _equ_type
                         ,int16[2] _atkLimit, int16[2] _defLimit ,int16[2] _hpLimit) public onlyManager{
    //設置合成防具資訊    

        armors_info[armors_id].equipt_name = _name;
        for(uint8 i = 0 ;i < _boxIndex.length;i++){
            armors_info[armors_id].boxIndex[i] = _boxIndex[i];
            armors_info[armors_id].materialIndex[i] = _materialIndex[i];
            armors_info[armors_id].amount[i] = _amount[i];
        }
        armors_info[armors_id].rarity = _rarity;
        armors_info[armors_id].equ_type = _equ_type;
        
        armors_ability[armors_id].atk_max = _atkLimit[0];
        armors_ability[armors_id].atk_min = _atkLimit[1];
        armors_ability[armors_id].def_max = _defLimit[0];
        armors_ability[armors_id].def_min = _defLimit[1];
        armors_ability[armors_id].hp_max = _hpLimit[0];
        armors_ability[armors_id].hp_min = _hpLimit[1];
        
    }
    
    
    function set_rings(uint16 rings_id,string _name, uint8[3] _boxIndex,uint8[3] _materialIndex, uint[3] _amount,uint8 _rarity,uint8 _equ_type
                         ,int16[2] _atkLimit, int16[2] _defLimit ,int16[2] _hpLimit) public onlyManager{
    //設置合成飾品資訊    

        rings_info[rings_id].equipt_name = _name;
        for(uint8 i = 0 ;i < _boxIndex.length;i++){
            rings_info[rings_id].boxIndex[i] = _boxIndex[i];
            rings_info[rings_id].materialIndex[i] = _materialIndex[i];
            rings_info[rings_id].amount[i] = _amount[i];
        }
        rings_info[rings_id].rarity = _rarity;
        rings_info[rings_id].equ_type = _equ_type;
        
        rings_ability[rings_id].atk_max = _atkLimit[0];
        rings_ability[rings_id].atk_min = _atkLimit[1];
        rings_ability[rings_id].def_max = _defLimit[0];
        rings_ability[rings_id].def_min = _defLimit[1];
        rings_ability[rings_id].hp_max = _hpLimit[0];
        rings_ability[rings_id].hp_min = _hpLimit[1];
    }
 
     
    //=================================融合================================================
    // function materialMix(uint16 city,uint16 id,uint8 proIndex, uint8[] mixArray) public {
    // //_id 土地 proIndex 要提升的屬性 
    //     require(msg.sender == master(master_address).inquire_owner(city,id));
    //     (uint16 _city,uint16 _id) = master(master_address).inquire_location(msg.sender);
    //     require(city == _city && id == _id);
         
    //     uint8 produce;        //欲增加屬性
    //     uint8 attribute; 
    //     uint8 index2;         //級距
    //     uint16 total = 0;     //機率總和 
    //     uint16 random = uint16((keccak256(abi.encodePacked(now, mixArray.length))));
  
         
    //     if(proIndex == 1){
    //         (produce,,,,,,,,,) = master(master_address).inquire_land_info(city,id);
             
    //     }else if(proIndex == 2){
    //         (,produce,,,,,,,,) = master(master_address).inquire_land_info(city,id);
    //     }else if(proIndex == 3){
    //         (,,produce,,,,,,,) = master(master_address).inquire_land_info(city,id);
    //     }else if(proIndex == 4){
    //         (,,,produce,,,,,,) = master(master_address).inquire_land_info(city,id);
    //     }else{
    //         (,,,,produce,,,,,) = master(master_address).inquire_land_info(city,id);
    //     }

    //     attribute = produce.add(master(master_address).inquire_tot_attribute(city,id)[(proIndex-1)]);//原本土地屬性 + 祝福屬性
        
    //     require(attribute>=0 && attribute < 10);//屬性上限為10
         
    //     //依現有等級級距去找相呼應的機率index
    //     if( attribute < 2)
    //         index2 = 0;
    //     else if(attribute > 1 && attribute < 4)
    //         index2 = 1; 
    //     else if(attribute > 3 && attribute < 6)
    //         index2 = 2;
    //     else if(attribute > 5 && attribute < 8)
    //         index2 = 3;
    //     else
    //         index2 = 4;  
            
    //     for(uint8 i=0;i<mixArray.length;i++){          //各個素材機率加總
    //         total = total.add(getParam(mixArray[i],index2));
    //     }
  
    //     for(i=0;i < mixArray.length; i++){                        //素材銷毀
            
    //         if(proIndex == 2){
    //             mixArray[i] = mixArray[i]%30;
    //         }else if(proIndex == 3){
    //             mixArray[i] = mixArray[i]%40;
    //         }else if(proIndex == 4){
    //             mixArray[i] = mixArray[i]%60;
    //         }else if(proIndex == 5){
    //             mixArray[i] = mixArray[i]%68;
    //         }

    //          material(material_address).control_burn((proIndex-1),(mixArray[i]-1),msg.sender,1);
    //     }  

    //     if((random%1000) <= total){
            
    //         master(master_address).domain_attribute(city, id, (proIndex-1));
    //         emit mix_result(msg.sender,true,total);
            
    //     } else{
    //         emit mix_result(msg.sender,false,total);
    //     }
    
    // }//融合
    
  
 
    //===========================================銷毀生成 + 額外素材=====================================================
    function composite(uint8 _type, uint16 _id,uint8[] _extra) public {
        require(_extra.length < 6);
        uint8[3] memory boxs;
        uint8[3] memory materials;
        uint[3] memory amounts;
        string memory equipt_name;
        // uint owner;
        
        ////原始需銷毀素材////
        if(_type == 1){
            boxs= weapons_info[_id].boxIndex;
            materials = weapons_info[_id].materialIndex;
            amounts = weapons_info[_id].amount;
            equipt_name = weapons_info[_id].equipt_name;
        }else if(_type == 2){
            boxs= armors_info[_id].boxIndex;
            materials = armors_info[_id].materialIndex;
            amounts = armors_info[_id].amount;
            equipt_name = armors_info[_id].equipt_name;
        }else if(_type == 3){
            boxs= rings_info[_id].boxIndex;
            materials = rings_info[_id].materialIndex;
            amounts = rings_info[_id].amount;
            equipt_name = rings_info[_id].equipt_name;
        }

        for(uint8 i=0;i < boxs.length; i++){
            uint matIndex = uint(materials[i]).add(uint(boxs[i]).mul(100)).add(2000);
            //uint matIndex = 2019;
            newMaterialsInterface(addr("newMats")).burn(matIndex, msg.sender, amounts[i]);
        }

        // owner = chaTokenInerface(changechaTokenContract).inquireOwnedTokensId(msg.sender);
        ////額外銷毀素材////
        if(_extra.length == 0) {
            EquipDemo(equ(_type)).createEquipment(msg.sender,equipt_name,_id,0,0);
        }

        else if(_extra.length == 1) {
             
            // require(skills(skills_address).inquire_skills(26,msg.sender)>=1 );
        
            
            // for(uint8 i=0;i<7;i++){
            //     chaTokenInerface(changechaTokenContract).inquireSkill()
            // }
            
            composite_extra(_extra[0]);
            EquipDemo(equ(_type)).createEquipment(msg.sender,equipt_name,_id,1,1);
        }
        
        else if(_extra.length == 2){
            // require(skills(skills_address).inquire_skills(26,msg.sender)>=2 );
            composite_extra(_extra[0],_extra[1]);
            EquipDemo(equ(_type)).createEquipment(msg.sender,equipt_name,_id,2,2);
        }
        
        else if(_extra.length == 3){
            // require(skills(skills_address).inquire_skills(26,msg.sender)>=3 );
            composite_extra(_extra[0],_extra[1],_extra[2]);
            EquipDemo(equ(_type)).createEquipment(msg.sender,equipt_name,_id,3,3);
        }
            
        else if(_extra.length == 4){
            // require(skills(skills_address).inquire_skills(26,msg.sender)>=4 );
            composite_extra(_extra[0],_extra[1],_extra[2],_extra[3]);
            EquipDemo(equ(_type)).createEquipment(msg.sender,equipt_name,_id,4,4);
        }
        
        else if(_extra.length == 5){
            // require(skills(skills_address).inquire_skills(26,msg.sender)>=5 );
            composite_extra(_extra[0],_extra[1],_extra[2],_extra[3],_extra[4]);
            EquipDemo(equ(_type)).createEquipment(msg.sender,equipt_name,_id,5,5);
        }
   
    }

    function composite_extra(uint _extra1) private{
        require(_extra1 >= 7101 && _extra1 <= 7120);
        newMaterialsInterface(addr("newMats")).burn(_extra1, msg.sender, 1);
    }
    
    function composite_extra(uint _extra1,uint _extra2) private{
        require(_extra2 >= 7121 && _extra2 <= 7140);
        require(_extra1 >= 7101 && _extra1 <= 7120);
        
        newMaterialsInterface(addr("newMats")).burn(_extra1, msg.sender, 1);
        newMaterialsInterface(addr("newMats")).burn(_extra2, msg.sender, 1);
    }
    function composite_extra(uint _extra1,uint _extra2,uint _extra3) private{
        require(_extra3 >= 7141 && _extra3 <= 7160);
        require(_extra2 >= 7121 && _extra2 <= 7140);
        require(_extra1 >= 7101 && _extra1 <= 7120);
        newMaterialsInterface(addr("newMats")).burn(_extra1,msg.sender,1);
        newMaterialsInterface(addr("newMats")).burn(_extra2,msg.sender,1);
        newMaterialsInterface(addr("newMats")).burn(_extra3,msg.sender,1);
    }
    function composite_extra(uint _extra1,uint _extra2,uint _extra3,uint _extra4) private{
        require(_extra4 >= 7161 && _extra4 <= 7180);
        require(_extra3 >= 7141 && _extra3 <= 7160);
        require(_extra2 >= 7121 && _extra2 <= 7140);
        require(_extra1 >= 7101 && _extra1 <= 7120);
        newMaterialsInterface(addr("newMats")).burn(_extra1,msg.sender,1);
        newMaterialsInterface(addr("newMats")).burn(_extra2,msg.sender,1);
        newMaterialsInterface(addr("newMats")).burn(_extra3,msg.sender,1);
        newMaterialsInterface(addr("newMats")).burn(_extra4,msg.sender,1);
    }
    function composite_extra(uint8 _extra1,uint8 _extra2,uint8 _extra3,uint8 _extra4,uint8 _extra5) private{
        require(_extra5 >= 7181 && _extra5 <= 7200);
        require(_extra4 >= 7161 && _extra4 <= 7180);
        require(_extra3 >= 7141 && _extra3 <= 7160);
        require(_extra2 >= 7121 && _extra2 <= 7140);
        require(_extra1 >= 7101 && _extra1 <= 7120);
        newMaterialsInterface(addr("newMats")).burn(_extra1,msg.sender,1);
        newMaterialsInterface(addr("newMats")).burn(_extra2,msg.sender,1);
        newMaterialsInterface(addr("newMats")).burn(_extra3,msg.sender,1);
        newMaterialsInterface(addr("newMats")).burn(_extra4,msg.sender,1);
        newMaterialsInterface(addr("newMats")).burn(_extra5,msg.sender,1);
    }
    


    // ===========================================生成裝備資訊=====================================================
    function inquireEquInfo(uint8 _type,uint _id) public view returns(string equipt_name,uint8[3] boxIndex, 
                                                      uint8[3] materialIndex,uint[3] amount,uint8 rarity,uint8 equ_type){
                                                          
        if(_type == 1){
            equipt_name = weapons_info[_id].equipt_name;
            boxIndex = weapons_info[_id].boxIndex;
            materialIndex = weapons_info[_id].materialIndex;
            amount = weapons_info[_id].amount;
            rarity = weapons_info[_id].rarity;
            equ_type = weapons_info[_id].equ_type;
        }else if(_type == 2){
            equipt_name = armors_info[_id].equipt_name;
            boxIndex = armors_info[_id].boxIndex;
            materialIndex = armors_info[_id].materialIndex;
            amount = armors_info[_id].amount;
            rarity = armors_info[_id].rarity;
            equ_type = armors_info[_id].equ_type;
        }else if(_type == 3){
            equipt_name = rings_info[_id].equipt_name;
            boxIndex = rings_info[_id].boxIndex;
            materialIndex = rings_info[_id].materialIndex;
            amount = rings_info[_id].amount;
            rarity = rings_info[_id].rarity;
            equ_type = rings_info[_id].equ_type;
        }                                                  
    }
    
    function inquireEquAbility(uint8 _type,uint _id) public view returns(int16 atk_max,int16 atk_min,int16 def_max,int16 def_min, 
                                                      int16 hp_max,int16 hp_min){
                                                          
        if(_type == 1){
            atk_max = weapons_ability[_id].atk_max;
            atk_min = weapons_ability[_id].atk_min;
            def_max = weapons_ability[_id].def_max;
            def_min = weapons_ability[_id].def_min;
            hp_max = weapons_ability[_id].hp_max;
            hp_min = weapons_ability[_id].hp_min;
        }else if(_type == 2){
            atk_max = armors_ability[_id].atk_max;
            atk_min = armors_ability[_id].atk_min;
            def_max = armors_ability[_id].def_max;
            def_min = armors_ability[_id].def_min;
            hp_max = armors_ability[_id].hp_max;
            hp_min = armors_ability[_id].hp_min;
        }else if(_type == 3){
            atk_max = rings_ability[_id].atk_max;
            atk_min = rings_ability[_id].atk_min;
            def_max = rings_ability[_id].def_max;
            def_min = rings_ability[_id].def_min;
            hp_max = rings_ability[_id].hp_max;
            hp_min = rings_ability[_id].hp_min;
        }                                                  
    }
    
    function inquire_equipts_address(uint8 equType) public view returns(address){
        return equ(equType);
    }

    
    function getParam(uint index1,uint16 index2) private view returns(uint16){     //祝福屬性機率 index1(素材) index2(級距)
           
           if(index1<6 || index1==31 || index1==32 || (index1>40 && index1<46) || index1==61 || index1==62 || (index1>68 && index1<74)){
               return paramA[index2];
           }else if((index1>5 && index1<11) || index1==33 || index1==34 || (index1>45 && index1<51) || index1==63 || index1==64 || (index1>73 && index1<79)){
               return paramB[index2];
           }else if((index1>10 && index1<16) || index1==35 || index1==36 || (index1>50 && index1<56) || index1==65 || index1==66 || (index1>78 && index1<84)){
               return paramC[index2];
           }else if((index1>15 && index1<21) || index1==37 || index1==38 || (index1>55 && index1<61)|| (index1>83 && index1<89)){
               return paramD[index2];
           }else if((index1>25 && index1<31) || index1==39 || index1==40 || index1==67 || index1==68){
               return paramF[index2];
           }else{
               return paramE[index2];
           }
    }
    
    
 
}
