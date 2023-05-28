// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.9;

import "./Libraries.sol";

interface Iupmas {
    function toStageConditions(uint256 _projectID) external view returns (bool);

    function toGateConditions(uint256 _projectID) external view returns (bool);

    function computeProjectReward(
        uint256 _projectID
    ) external view returns (uint256);

    function getDeclinedTasksIDs(
        uint256 _projectID
    ) external view returns (uint256[] memory);
}
