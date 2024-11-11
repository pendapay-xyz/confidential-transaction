pragma solidity >=0.7.0 <0.9.0;

interface IPlonkVerifier {
    function verifyProof(uint256[24] memory _proof, uint256[6] memory _pubSignals) external view returns (bool);
}
