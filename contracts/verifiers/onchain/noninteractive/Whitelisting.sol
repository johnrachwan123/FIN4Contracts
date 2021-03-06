pragma solidity ^0.5.17;

import "contracts/verifiers/Fin4BaseVerifierType.sol";
import "contracts/Fin4Groups.sol";

contract Whitelisting is Fin4BaseVerifierType { // TODO make it extend Blacklisting?

    constructor() public  {
        name = "Whitelisting";
        description = "The token creator defines group(s) and/or individual accounts that can claim a token while everyone else can not";
        isNoninteractive = true;
    }

    address public Fin4GroupsAddress;

    function setFin4GroupsAddress(address Fin4GroupsAddr) public {
        Fin4GroupsAddress = Fin4GroupsAddr;
    }

    // @Override
    function autoCheck(address user, address tokenAddress, uint claimId) public {
        if (arrayContainsAddress(tokenToWhitelistedUsers[tokenAddress], user) ||
            Fin4Groups(Fin4GroupsAddress).userIsInOneOfTheseGroups(tokenToWhitelistedGroups[tokenAddress], user)) {
            _sendApprovalNotice(address(this), tokenAddress, claimId, "");
        } else {
            string memory message = string(abi.encodePacked(
                "Your claim on token \'",
                Fin4TokenStub(tokenAddress).name(),
                "\' got rejected from the noninteractive verifier \'Whitelisting\' because you are note whitelisted on this token"
                " - neither directly nor via group membership"));
            _sendRejectionNotice(address(this), tokenAddress, claimId, message);
        }
    }

    // @Override
    function getParameterForTokenCreatorToSetEncoded() public pure returns(string memory) {
        return "address[]:whitelisted users:,uint[]:whitelisted groups:";
    }

    // TODO use boolean-mapping for value instead? 
    mapping (address => address[]) public tokenToWhitelistedUsers;
    mapping (address => uint[]) public tokenToWhitelistedGroups;

    function setParameters(address token, address[] memory whitelistedUsers, uint[] memory whitelistedGroupIds) public {
        tokenToWhitelistedUsers[token] = whitelistedUsers;
        tokenToWhitelistedGroups[token] = whitelistedGroupIds;
    }

}
