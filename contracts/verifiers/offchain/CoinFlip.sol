pragma solidity ^0.5.17;

import "contracts/provable/provableAPI_0.5.sol";
import "contracts/verifiers/Fin4BaseVerifierType.sol";

contract CoinFlip is usingProvable, Fin4BaseVerifierType {
    string public RESULT_PROPERTY = "Result";
    string public BASE_URL = "http://coin-flip-api.herokuapp.com/flip?claim=";

    event LogNewProvableQuery(string description);
    event LogNewProvableResult(string result);

    struct Claim {
        address tokenAddrToReceiveVerifierNotice;
        uint256 claimId;
        bool pending;
    }
    mapping(bytes32 => Claim) public pendingQueries;

    constructor() public payable {
        name = "CoinFlip";
        description = "A coinflip from the claimer [0/1] has to match the verifier's coinflip.";
    }

    function append(string memory claimFlip)
        internal
        view
        returns (string memory)
    {
        return
            string(
                abi.encodePacked(
                    "json(",
                    BASE_URL,
                    claimFlip,
                    ").",
                    RESULT_PROPERTY
                )
            );
    }

    function __callback(bytes32 myId, string memory result) public {
        Claim memory claim = pendingQueries[myId];
        // require(msg.sender == provable_cbAddress());
        // require(claim.pending == true);
        emit LogNewProvableResult(result);
        if (
            keccak256(abi.encodePacked((result))) ==
            keccak256(abi.encodePacked(("true")))
        ) {
            _sendApprovalNotice(
                address(this),
                claim.tokenAddrToReceiveVerifierNotice,
                claim.claimId,
                ""
            );
        } else {
            string memory message = string(
                abi.encodePacked(
                    "Your claim on token '",
                    Fin4TokenStub(claim.tokenAddrToReceiveVerifierNotice)
                        .name(),
                    "' got rejected from verifier type 'CoinFlip' because",
                    " your flip did not match with the verifier's flip."
                )
            );
            _sendRejectionNotice(
                address(this),
                claim.tokenAddrToReceiveVerifierNotice,
                claim.claimId,
                message
            );
        }
        delete pendingQueries[myId]; // This effectively marks the query id as processed.
    }

    function submitProof_CoinFlip(
        address tokenAddrToReceiveVerifierNotice,
        uint256 claimId,
        string memory claimFlip
    ) public payable {
        Claim memory c;
        if (provable_getPrice("URL") > msg.value) {
            revert(
                "Provable query was NOT sent, please add some ETH to cover for the query fee!"
            );
        } else {
            bytes32 queryId = provable_query("URL", append(claimFlip));
            c.tokenAddrToReceiveVerifierNotice = tokenAddrToReceiveVerifierNotice;
            c.claimId = claimId;
            c.pending = true;
            pendingQueries[queryId] = c;
            _sendPendingNotice(address(this), tokenAddrToReceiveVerifierNotice, claimId);
            emit LogNewProvableQuery(
                "Provable query was sent, standing by for the answer..."
            );
        }
    }
}
