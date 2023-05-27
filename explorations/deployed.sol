// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.9;

import "./Ideployed.sol";

contract deployed {

    address public addressB;

    mapping (uint256 => theStructs.Test) public tests;

    function setAddressB (address _addressB) public {
        require(addressB == address(0), "addressB must be set once");
        addressB = _addressB;
    }

    function makeTest (uint256 _id, string memory _name) public returns (theStructs.Test memory){
        tests[_id] = theStructs.Test(_id, _name);
        return tests[_id];
    }

    // function getTest (uint256 _id) public view returns (theStructs.Test memory) {
    //     return tests[_id];
    // }

    function doubleMartin (uint256 _id) public returns (theStructs.Test memory, bool) {
        bool isMartin = IcontractB(addressB).giveCondition(_id);

        if (isMartin) {
            makeTest(_id+1, "Martin Two");
            return (tests[_id+1], true);
        } else {
            return (tests[_id], false);
        }
    }
    
}