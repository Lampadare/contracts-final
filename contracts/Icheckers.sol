// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.9;

import "./FundingsManager.sol";
import "./ProjectManager.sol";
import "./CampaignManager.sol";
import "./TaskManager.sol";
import "./Utilities.sol";

interface Icheckers {
    function toStageConditions(uint256 _projectID) external view returns (bool, bool);
    function toGateConditions(uint256 _projectID) external view returns (bool, bool);
}