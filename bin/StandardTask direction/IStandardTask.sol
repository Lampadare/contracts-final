// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.9;

import "./Libraries.sol";

interface IStandardTask {
    function getTask(
        uint256 _taskID
    ) external view returns (TaskManager.Task memory);
}
