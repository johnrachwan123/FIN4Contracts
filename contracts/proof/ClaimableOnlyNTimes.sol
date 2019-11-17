pragma solidity ^0.5.0;

import "contracts/proof/Fin4BaseProofType.sol";

contract ClaimableOnlyNTimes is Fin4BaseProofType {

    constructor(address Fin4MessagingAddress)
    Fin4BaseProofType(Fin4MessagingAddress)
    public {
        name = "ClaimableOnlyNTimes";
        description = "The token creator sets a cap how many times a token can be claimed";
    }

  function submitProof_ClaimableOnlyNTimes(address tokenAddrToReceiveProof, uint claimId) public {
      uint usersClaimCountOnToken = userToTheirClaimsCountOnToken[msg.sender][tokenAddrToReceiveProof];
      uint cap = tokenToClaimsCap[tokenAddrToReceiveProof];
      if (usersClaimCountOnToken == cap) {
          string memory message = string(abi.encodePacked(
              "Your claim on token \'",
              Fin4TokenStub(tokenAddrToReceiveProof).name(),
              "\' got rejected from proof type \'ClaimableOnlyNTimes\' because you reached the",
              " maximum number of claims as capped by the token creator: ", uint2str(cap)));
          Fin4Messaging(Fin4MessagingAddress).addInfoMessage(address(this), msg.sender, message);
      } else {
          _sendApproval(address(this), tokenAddrToReceiveProof, claimId);
          userToTheirClaimsCountOnToken[msg.sender][tokenAddrToReceiveProof] = usersClaimCountOnToken + 1;
      }
  }

  // @Override
  function getParameterForTokenCreatorToSetEncoded() public pure returns(string memory) {
      return "uint:max. claims:";
  }

  mapping (address => uint) public tokenToClaimsCap;
  mapping (address => mapping (address => uint)) public userToTheirClaimsCountOnToken; // user, token, claims count

  function setParameters(address token, uint claimsCap) public {
      tokenToClaimsCap[token] = claimsCap;
  }

}