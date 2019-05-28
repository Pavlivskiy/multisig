pragma solidity ^0.4.24;

contract MultiSig {

    mapping(address => bool) private own;

    uint256 public spendNonce = 0;
    uint256 public unchainedMultisigVersionMajor = 2;
    uint256 public unchainedMultisigVersionMinor = 0;
    event Funded(uint newBalance);
    event Spent(address to, uint transfer);
    constructor(address addressFirst, address addressSecond, address addressThird) public {
        address zeroAddress = 0x0;

        require(addressFirst != zeroAddress, "1");
        require(addressSecond != zeroAddress, "1");
        require(addressThird != zeroAddress, "1");

        require(addressFirst != addressSecond, "1");
        require(addressSecond != addressThird, "1");
        require(addressFirst != addressThird, "1");

        own[addressFirst] = true;
        own[addressSecond] = true;
        own[addressThird] = true;
    }
    function() public payable {
        emit Funded(address(this).balance);
    }
    function generateMessageToSign(address dest, uint256 value) public view returns (bytes32) {
        require(dest != address(this), "2");
        bytes32 message = keccak256( abi.encodePacked(spendNonce, this, value, dest));
        return message;
    }
    function spend( address dest, uint256 value, uint8 v1, bytes32 r1, bytes32 s1, uint8 v2, bytes32 r2, bytes32 s2 ) public {
        require(address(this).balance >= value, "3");
        require( _validSignature( dest, value, v1, r1, s1, v2, r2, s2 ), "4");
        spendNonce = spendNonce + 1;
        dest.transfer(value);
        emit Spent(dest, value);
    }
    function _validSignature( address dest, uint256 value, uint8 v1, bytes32 r1, bytes32 s1, uint8 v2, bytes32 r2, bytes32 s2) private view returns (bool) {
        bytes32 message = _messageToRecover(dest, value);
        address addr1 = ecrecover( message, v1+27, r1, s1);
        address addr2 = ecrecover( message, v2+27, r2, s2);
        require(_distinctOwners(addr1, addr2), "5");

        return true;
    }
    function _messageToRecover(address dest, uint256 value) private view returns (bytes32) {
        bytes32 hashedUnsignedMessage = generateMessageToSign( dest, value);
        bytes memory unsignedMessageBytes = _hashToAscii( hashedUnsignedMessage);
        bytes memory prefix = "\x19Ethereum Signed Message:\n64";
        return keccak256(abi.encodePacked(prefix,unsignedMessageBytes));
    }
    function _distinctOwners(address addr1, address addr2) private view returns (bool) {
        require(addr1 != addr2, "5");
        require(own[addr1], "5");
        require(own[addr2], "5");
        return true;
    }
    function _hashToAscii(bytes32 hash) private pure returns (bytes) {
        bytes memory s = new bytes(64);
        for (uint i = 0; i < 32; i++) {
            byte  b = hash[i];
            byte hi = byte(uint8(b) / 16);
            byte lo = byte(uint8(b) - 16 * uint8(hi));
            s[2*i] = _char(hi);
            s[2*i+1] = _char(lo);
        }
        return s;
    }
    function _char(byte b) private pure returns (byte c) {
        if (b < 10) {
            return byte(uint8(b) + 0x30);
        } else {
            return byte(uint8(b) + 0x57);
        }
    }
}
