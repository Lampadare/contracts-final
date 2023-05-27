// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.9;

library theStructs {
    struct Test {
        uint256 id;
        string name;
    }
}

interface Ideployed {
    // struct Test {
    //     uint256 id;
    //     string name;
    // }

    function getTest (uint256 _id) external view returns (theStructs.Test memory);
}

interface IcontractB {
    function getTestFromDeployed (uint256 _id) external view returns (theStructs.Test memory);
    function giveCondition(uint256 _id) external view returns (bool);
}