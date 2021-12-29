pragma solidity ^0.8.0;

contract Helper{
    function getUintData(string calldata functionName, uint256 a, uint b) public pure returns(bytes memory){
        return abi.encodeWithSignature(functionName, a, b);
    }
    
    function getStringData(string calldata functionName, string calldata a, string calldata b) public pure returns(bytes memory){
        return abi.encodeWithSignature(functionName, a, b);
    }
    
    function getAddressData(string calldata functionName, address a, address b) public pure returns(bytes memory){
        return abi.encodeWithSignature(functionName, a, b);
    }
}