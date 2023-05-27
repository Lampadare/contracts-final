// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.9;

import "./Ideployed.sol";

contract B {
    address deployed_address;

    constructor (address _deployed_address) {
        deployed_address = _deployed_address;
    }

    function getTestFromDeployed (uint256 _id) public view returns (theStructs.Test memory) {
        return Ideployed(deployed_address).getTest(_id);
    }

    function giveCondition(uint256 _id) public view returns (bool) {
        theStructs.Test memory test = Ideployed(deployed_address).getTest(_id);

        if (keccak256(abi.encodePacked((test.name))) == keccak256(abi.encodePacked(("Martin")))) {
            return true;
        } else {
            return false;
        }
    }
}