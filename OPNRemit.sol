// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title OPN Remit
 * @notice Borderless payments on OPN Chain
 * @dev Fast, low-cost remittance protocol
 */
contract OPNRemit {
    address public owner;
    uint256 public feePercent = 1; // 1% fee
    uint256 public totalSent;
    uint256 public totalTransactions;

    struct Transfer {
        address sender;
        address receiver;
        uint256 amount;
        uint256 fee;
        uint256 timestamp;
        string note;
    }

    mapping(address => Transfer[]) public sentHistory;
    mapping(address => Transfer[]) public receivedHistory;
    mapping(address => uint256) public totalSentByUser;

    event Moneysent(
        address indexed sender,
        address indexed receiver,
        uint256 amount,
        uint256 fee,
        string note
    );

    event FeeUpdated(uint256 newFee);

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner");
        _;
    }

    function sendMoney(
        address payable receiver,
        string memory note
    ) public payable {
        require(msg.value > 0, "Amount must be greater than 0");
        require(receiver != address(0), "Invalid receiver");
        require(receiver != msg.sender, "Cannot send to yourself");

        uint256 fee = (msg.value * feePercent) / 100;
        uint256 amountAfterFee = msg.value - fee;

        Transfer memory newTransfer = Transfer({
            sender: msg.sender,
            receiver: receiver,
            amount: amountAfterFee,
            fee: fee,
            timestamp: block.timestamp,
            note: note
        });

        sentHistory[msg.sender].push(newTransfer);
        receivedHistory[receiver].push(newTransfer);

        totalSent += amountAfterFee;
        totalTransactions += 1;
        totalSentByUser[msg.sender] += amountAfterFee;

        receiver.transfer(amountAfterFee);
        payable(owner).transfer(fee);

        emit Moneysent(msg.sender, receiver, amountAfterFee, fee, note);
    }

    function getSentHistory(
        address user
    ) public view returns (Transfer[] memory) {
        return sentHistory[user];
    }

    function getReceivedHistory(
        address user
    ) public view returns (Transfer[] memory) {
        return receivedHistory[user];
    }

    function updateFee(uint256 newFee) public onlyOwner {
        require(newFee <= 5, "Fee cannot exceed 5%");
        feePercent = newFee;
        emit FeeUpdated(newFee);
    }

    function getContractStats() public view returns (
        uint256 _totalSent,
        uint256 _totalTransactions,
        uint256 _feePercent
    ) {
        return (totalSent, totalTransactions, feePercent);
    }
}