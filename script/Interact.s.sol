// SPDX-Licnece-Identifier: MIT

pragma solidity ^0.8.24;

import {Script} from "forge-std/Script.sol";
import {DevOpsTools} from "foundry-devops/src/DevOpsTools.sol";
import {MerkleAirdrop} from "../src/MerkleAirdrop.sol";

contract ClaimAirdrop is Script {
    error ClaimAirdropScript__InvalidSignatureLength();

    //Default anvil address
    address CLAIMING_ADDRESS = 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266;
    uint256 CLAIMING_AMOUNT = 25 * 1e18;

    //We got this by calling following commands
    // cast call 0xe7f1725E7734CE288F8367e1Bb143E90bb3F0512 "getMessageHash(address, uint256)" \
    // 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266 25000000000000000000 --rpc-url http://localhost:8545

    // Attention: we signed it using private key of first default anvil user
    //cast wallet sign --no-hash 0x184e30c4b19f5e304a89352421dc50346dad61c461e79155b910e73fd856dc72 \
    // --private-key 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80

    //First run anvil and deploy contracts using Makefile

    //When calling script we are using second default anvil user (private key)
    // forge script script/Interact.s.sol:ClaimAirdrop --rpc-url http://localhost:8545 \
    // --private-key 0x59c6995e998f97a5a0044966f0945389dc9e86dae88c7a8412f4603b6b78690d --broadcast

    // We can check if script worked by checking user1 balance
    // cast call 0x5FbDB2315678afecb367f032d93F642f64180aa3 "balanceOf(address)" 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266

    bytes private SIGNATURE =
        hex"fbd2270e6f23fb5fe9248480c0f4be8a4e9bd77c3ad0b1333cc60b5debc511602a2a06c24085d8d7c038bad84edc53664c8ce0346caeaa3570afec0e61144dc11c";

    bytes32[] public PROOF = [
        bytes32(0xd1445c931158119b00449ffcac3c947d028c0c359c34a6646d95962b3b55c6ad),
        bytes32(0xe5ebd1e1b5a5478a944ecab36a9a954ac3b6b8216875f6524caa7a1d87096576)
    ];

    function splitSignature(bytes memory sig) public pure returns (uint8 v, bytes32 r, bytes32 s) {
        // v = 1byte, r = 32bytes, s = 32bytes
        if (sig.length != 65) {
            revert ClaimAirdropScript__InvalidSignatureLength();
        }
        assembly {
            //First 32bytes is length prefix found in bytes
            r := mload(add(sig, 32))
            s := mload(add(sig, 64))
            // Loads 32bytes from +96 offset, but takes just first byte
            v := byte(0, mload(add(sig, 96)))
        }
    }

    function claimAirdrop(address airdropAddress) public {
        vm.startBroadcast();
        (uint8 v, bytes32 r, bytes32 s) = splitSignature(SIGNATURE);
        MerkleAirdrop(airdropAddress).claim(CLAIMING_ADDRESS, CLAIMING_AMOUNT, PROOF, v, r, s);
        vm.stopBroadcast();
    }

    function run() external {
        address mostRecentDeployed = DevOpsTools.get_most_recent_deployment("MerkleAirdrop", block.chainid);
        claimAirdrop(mostRecentDeployed);
    }
}
