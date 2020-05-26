pragma solidity ^0.5.17;

import "contracts/verifiers/Fin4BaseVerifierType.sol";
import "contracts/Fin4TokenBase.sol";
import "contracts/Fin4Groups.sol";
import "contracts/Fin4Messaging.sol";
import "contracts/Fin4TokenManagement.sol";

contract LimitedVoting is Fin4BaseVerifierType {
     constructor() public  {
        creator = msg.sender;
        init();
    }

    address public creator;
    address public Fin4GroupsAddress;
    address public Fin4MessagingAddress;
    address public Fin4ReputationAddress;
    address public Fin4TokenManagementAddr;
    // Set in 2_deploy_contracts.js
    function setFin4GroupsAddress(address Fin4GroupsAddr) public {
        Fin4GroupsAddress = Fin4GroupsAddr;
    }
    // Set in 2_deploy_contracts.js
    function setFin4tokenManagementAddress(address Fin4TokenManagementAddress) public {
        Fin4TokenManagementAddr = Fin4TokenManagementAddress;
    }
    // Set in 2_deploy_contracts.js
    function setFin4MessagingAddress(address Fin4MessagingAddr) public {
        Fin4MessagingAddress = Fin4MessagingAddr;
    }
    function setFin4ReputationAddress(address Fin4ReputationAddr) public {
        require(msg.sender == creator, "Only the creator of this smart contract can call this function");
        Fin4ReputationAddress = Fin4ReputationAddr;
    }

    // @Override
    function init() public {
        name = "LimitedVoting";
        description = "The proof is sent to the users due to a random mechanism";
        isAutoInitiable = true;
    }

    uint public nextPendingApprovalId = 0;
    mapping (uint => PendingApproval) public pendingApprovals; // just use an array? TODO

    struct PendingApproval {
        uint pendingApprovalId;
        address tokenAddrToReceiveVerifierNotice;
        uint claimIdOnTokenToReceiveVerifierDecision;
        address requester;

        bool isIndividualApprover; // false means group-usage

        uint approverGroupId;
        // the following two arrays belong tightly together
        address[] groupMemberAddresses; // store a snapshot of those here or not? #ConceptualDecision
                                        // if not, a mechanism to mark messages as read is needed
        uint[] messageIds;
        uint[] reputation;
        string attachment;
        uint nbApproved;
        uint nbRejected;
        bool isApproved; // in case of multiple PendingApprovals waiting for each other
        uint linkedWithPendingApprovalId;
    }

    // @Override
    function autoSubmitProof(address user, address tokenAddrToReceiveVerifierNotice, uint claimId) public {
        PendingApproval memory pa;
        pa.tokenAddrToReceiveVerifierNotice = tokenAddrToReceiveVerifierNotice;
        pa.claimIdOnTokenToReceiveVerifierDecision = claimId;
        pa.requester = user;
        uint groupId = _getGroupId(tokenAddrToReceiveVerifierNotice);
        pa.approverGroupId = groupId;
        pa.pendingApprovalId = nextPendingApprovalId;
        pa.nbApproved = 0;
        pa.nbRejected = 0;
        pa.isIndividualApprover = false;

        string memory message = string(abi.encodePacked(getMessageText(), Fin4TokenBase(tokenAddrToReceiveVerifierNotice).name(),
            ". Once a member of the group approves, these messages get marked as read for all others."));

        address[] memory members = Fin4Groups(Fin4GroupsAddress).getGroupMembers(groupId);

        pa.groupMemberAddresses = new address[](members.length);
        pa.messageIds = new uint[](members.length);
        for (uint i = 0; i < members.length; i ++) {
            pa.groupMemberAddresses[i] = members[i];
            pa.reputation[i] = Fin4TokenManagement(Fin4TokenManagementAddr).getBalance(members[i], Fin4ReputationAddress);
            // Fin4TokenManagement(Fin4TokenManagementAddr);
            pa.messageIds[i] = Fin4Messaging(Fin4MessagingAddress)
                .addPendingApprovalMessage(user, name, members[i], message, "", pa.pendingApprovalId);
        }

        pendingApprovals[nextPendingApprovalId] = pa;
        nextPendingApprovalId ++;

        _sendPendingNotice(address(this), tokenAddrToReceiveVerifierNotice, claimId);
    }

    function getMessageText() public pure returns(string memory) {
        return "You are a member of a user group that was appointed for approving this claim on the token ";
    }

    // @Override
    function getParameterForTokenCreatorToSetEncoded() public pure returns(string memory) {
      return "uint:Number of Users";
    }
    // TO DO: Make this parameter actually number of users instead of group id
    mapping (address => uint) public tokenToParameter;

    function setParameters(address token, uint groupId) public {
    //   require(Fin4Groups(Fin4GroupsAddress).groupExists(groupId), "Group ID does not exist");
      tokenToParameter[token] = groupId;
    }

    function _getGroupId(address token) public view returns(uint) {
        return tokenToParameter[token];
    }

    // copied method signature from SpecificAddress, then nothing has to be changed in Messages.jsx

    function receiveApprovalFromSpecificAddress(uint pendingApprovalId, string memory attachedMessage) public {
        PendingApproval memory pa = pendingApprovals[pendingApprovalId];
        require(Fin4Groups(Fin4GroupsAddress).isMember(pa.approverGroupId, msg.sender), "You are not a member of the appointed approver group");
        markMessageAsRead(pendingApprovalId, Fin4Groups(Fin4GroupsAddress).getIndexOfMember(pa.approverGroupId, msg.sender));
        pa.nbApproved = pa.nbApproved + 1;
        if(pa.nbApproved > pa.groupMemberAddresses.length/2){
            markMessagesAsRead(pendingApprovalId);
            _sendApprovalNotice(address(this), pa.tokenAddrToReceiveVerifierNotice, pa.claimIdOnTokenToReceiveVerifierDecision, attachedMessage);
        }
        pendingApprovals[pendingApprovalId] = pa;
    }

    function receiveRejectionFromSpecificAddress(uint pendingApprovalId, string memory attachedMessage) public {
        PendingApproval memory pa = pendingApprovals[pendingApprovalId];
        require(Fin4Groups(Fin4GroupsAddress).isMember(pa.approverGroupId, msg.sender), "You are not a member of the appointed approver group");
        markMessageAsRead(pendingApprovalId, Fin4Groups(Fin4GroupsAddress).getIndexOfMember(pa.approverGroupId, msg.sender));
        string memory message = string(abi.encodePacked(
            "A member of the appointed approver group has rejected your approval request for ",
            Fin4TokenBase(pa.tokenAddrToReceiveVerifierNotice).name()));
        if (bytes(attachedMessage).length > 0) {
            message = string(abi.encodePacked(message, ': ', attachedMessage));
        }
        pa.nbRejected = pa.nbRejected + 1;
        if(pa.nbRejected > pa.groupMemberAddresses.length/2){
            markMessagesAsRead(pendingApprovalId);
            _sendRejectionNotice(address(this), pa.tokenAddrToReceiveVerifierNotice, pa.claimIdOnTokenToReceiveVerifierDecision, message);
        }
        pendingApprovals[pendingApprovalId] = pa;
    }

    function markMessagesAsRead(uint pendingApprovalId) public {
        PendingApproval memory pa = pendingApprovals[pendingApprovalId];
        for (uint i = 0; i < pa.messageIds.length; i ++) {
            Fin4Messaging(Fin4MessagingAddress).markMessageAsActedUpon(pa.groupMemberAddresses[i], pa.messageIds[i]);
        }
    }

    function markMessageAsRead(uint pendingApprovalId, uint index) public {
        PendingApproval memory pa = pendingApprovals[pendingApprovalId];
        Fin4Messaging(Fin4MessagingAddress).markMessageAsActedUpon(pa.groupMemberAddresses[index], pa.messageIds[index]);
    }
}