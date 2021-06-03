pragma solidity >= 0.4.25;

///////////////////////////////////////////////////////
/////////////////Library And interface/////////////////
///////////////////////////////////////////////////////

library Address {

    function isContract(address account) internal view returns (bool) {

        uint256 size;

        assembly{size := extcodesize(account)}
        return size > 0;
    }
}

interface IERC165 {

    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

 contract ERC165 is IERC165 {

    bytes4 private constant _INTERFACE_ID_ERC165 = 0x01ffc9a7;

    mapping(bytes4 => bool) private _supportedInterfaces;

    constructor () internal {

        _registerInterface(_INTERFACE_ID_ERC165);
    }

    function supportsInterface(bytes4 interfaceId) external view returns (bool) {
        return _supportedInterfaces[interfaceId];
    }

    function _registerInterface(bytes4 interfaceId) internal {
        require(interfaceId != 0xffffffff, "ERC165: invalid interface id");
        _supportedInterfaces[interfaceId] = true;
    }
}

contract IERC721Receiver {
    function onERC721Received(address operator, address from, uint256 tokenId, bytes memory data)
    public returns (bytes4);
}

contract IERC721 is IERC165 {
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    function balanceOf(address owner) public view returns (uint256 balance);

    function ownerOf(uint256 tokenId) public view returns (address owner);

    function safeTransferFrom(address from, address to, uint256 tokenId) public;

    function transferFrom(address from, address to, uint256 tokenId) public;
    function approve(address to, uint256 tokenId) public;
    function getApproved(uint256 tokenId) public view returns (address operator);

    function setApprovalForAll(address operator, bool _approved) public;
    function isApprovedForAll(address owner, address operator) public view returns (bool);

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) public;
}

contract ERC721 is ERC165, IERC721{
    
    using Address for address;

    bytes4 internal constant _ERC721_RECEIVED = 0x150b7a02;
    // bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))

    bytes4 internal constant _INTERFACE_ID_ERC721 = 0x80ac58cd;
    //Refer https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC721/ERC721.sol

    mapping (uint256 => address) internal _tokenOwner; //token擁有者(erc721標準)
    mapping (uint256 => address) internal _tokenApprovals; //token轉移權(erc721標準)
    mapping (address => uint) internal _ownedTokensCount;  //擁有token數量(erc721標準)
    mapping (address => mapping (address => bool)) internal _operatorApprovals; //token操作擁有權(erc721標準)

    string public name;   //該erc721名稱
    string public symbol; //該erc721簡寫

    constructor() public{
        _registerInterface(_INTERFACE_ID_ERC721);
    }
}