pragma solidity ^0.5.17;
// Stub that allows smart forwarding of calls to verifier contracts
contract Fin4VerifyingStub {
    // Proof Submission
    function submitProof_PictureVoting(address tokenAddrToReceiveVerifierNotice, uint claimId, address claimer, string memory IPFShash) public;
    function submitProof_LimitedVoting(address tokenAddrToReceiveVerifierNotice, uint claimId,address claimer, string memory IPFShash) public;
    function submitProof_VideoVoting(address tokenAddrToReceiveVerifierNotice, uint claimId, address claimer, string memory IPFShash) public;
    function submitProof_Picture(address tokenAddrToReceiveVerifierNotice, uint claimId, address claimer, address approver, string memory IPFShash) public;
    function submitProof_SpecificAddress(address tokenAddrToReceiveVerifierNotice, uint claimId, address claimer, address approver) public;
    function submitProof_Location_Server(address tokenAddrToReceiveVerifierNotice, uint claimId, int256 lat1, int256 lon1) public;
    function submitProof_TokenCreatorApproval(address tokenAddrToReceiveVerifierNotice, uint claimId, address claimer) public;
    function submitProof_Password(address tokenAddrToReceiveVerifierNotice, uint claimId, string memory password) public;
    function submitProof_MaximumQuantityPerInterval(address tokenAddrToReceiveVerifierNotice, uint claimId) public;
    function submitProof_MinimumInterval(address tokenAddrToReceiveVerifierNotice, uint claimId) public;
    function submitProof_SelfApprove(address tokenAddrToReceiveVerifierNotice, uint claimId) public;
    function submitProof_CoinFlip(address tokenAddrToReceiveVerifierNotice, uint claimId, string memory claimFlip) public payable;
    function sensorSignalReceived(string memory sensorID, uint timestamp, string memory data) public;
    // Set Verifier Parameters
    function setParameters(address token, address[] memory param1, uint[] memory param2) public;
    function setParameters(address token, uint param1) public;
    function setParameters(address token, string memory param1, uint param2) public;
    function setParameters(address token, uint param1, uint param2) public;
    function setParameters(address token, string memory param1) public;
    // Voting Interaction
    function receiveApprovalFromSpecificAddress(uint param1, address param2, string memory param3) public;
    function receiveRejectionFromSpecificAddress(uint param1, address param2, string memory param3) public;
    function endVote(uint claimId) public;
    function becomeVoter(address voter) public;
    function isEligibleToBeAVoter(address voter) public returns(bool);
}
