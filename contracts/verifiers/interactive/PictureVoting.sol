pragma solidity ^0.5.17;

import "contracts/verifiers/interactive/LimitedVoting.sol";

contract PictureVoting is LimitedVoting {

    constructor() public  {}

    // @Override
    function init() public {
        name = "PictureVoting";
        description = "The claimer has to supply a picture, based on which the approver will decide to approve.";
    }

    function submitProof_PictureVoting(address tokenAddrToReceiveVerifierNotice, uint claimId, string memory IPFShash) public {
        super.submitProof_LimitedVoting(tokenAddrToReceiveVerifierNotice, claimId, IPFShash);
    }

    // @Override
    function getMessageText() public pure returns(string memory) {
        // TODO include the quantity into the message
        return "Please check this picture verifier and approve the correct amount of this token: ";
    }

}