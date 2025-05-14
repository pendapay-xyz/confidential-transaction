// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.18;

contract Profile {
    mapping(address => mapping(bytes32 => bytes)) private _profiles;

    event ProfileUpdated(address indexed user, bytes32 indexed key, bytes value);

    function setProfile(bytes32 key, bytes memory value) public {
        _profiles[msg.sender][key] = value;
        emit ProfileUpdated(msg.sender, key, value);
    }
}