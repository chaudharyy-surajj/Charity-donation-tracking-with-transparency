// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

contract CharityDonationTracker {

    // State variables
    address public owner;
    uint256 public totalDonationsReceived;
    uint256 public totalDonationsWithdrawn;

    // Structs
    struct Donation {
        address donor;
        uint256 amount;
        uint256 timestamp;
        string message;
    }

    // Arrays and mappings
    Donation[] public donations;
    mapping(address => uint256) public donorTotalContributions;

    // Events
    event DonationReceived(address indexed donor, uint256 amount, string message, uint256 timestamp);
    event FundsWithdrawn(address indexed owner, uint256 amount, uint256 timestamp);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    // Modifiers
    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function");
        _;
    }

    modifier validAmount() {
        require(msg.value > 0, "Donation amount must be greater than 0");
        _;
    }

    // Constructor
    constructor() {
        owner = msg.sender;
    }

    // Function 1: Donate to charity with optional message
    function donate(string memory _message) external payable validAmount {
        donations.push(Donation({
            donor: msg.sender,
            amount: msg.value,
            timestamp: block.timestamp,
            message: _message
        }));

        donorTotalContributions[msg.sender] += msg.value;
        totalDonationsReceived += msg.value;

        emit DonationReceived(msg.sender, msg.value, _message, block.timestamp);
    }

    // Function 2: Get donation details by index
    function getDonation(uint256 _index) external view returns (
        address donor,
        uint256 amount,
        uint256 timestamp,
        string memory message
    ) {
        require(_index < donations.length, "Invalid donation index");

        Donation memory donation = donations[_index];
        return (donation.donor, donation.amount, donation.timestamp, donation.message);
    }

    // Function 3: Get transparency report
    function getTransparencyReport() external view returns (
        uint256 totalReceived,
        uint256 totalWithdrawn,
        uint256 currentBalance,
        uint256 totalDonations,
        uint256 uniqueDonors
    ) {
        return (
            totalDonationsReceived,
            totalDonationsWithdrawn,
            address(this).balance,
            donations.length,
            getDonorCount()
        );
    }

    // Function 4: Withdraw funds (only owner)
    function withdrawFunds(uint256 _amount) external onlyOwner {
        require(_amount <= address(this).balance, "Insufficient contract balance");
        require(_amount > 0, "Withdrawal amount must be greater than 0");

        totalDonationsWithdrawn += _amount;

        (bool success, ) = payable(owner).call{value: _amount}("");
        require(success, "Withdrawal failed");

        emit FundsWithdrawn(owner, _amount, block.timestamp);
    }

    // Function 5: Transfer ownership
    function transferOwnership(address _newOwner) external onlyOwner {
        require(_newOwner != address(0), "New owner cannot be zero address");
        require(_newOwner != owner, "New owner must be different from current owner");

        address previousOwner = owner;
        owner = _newOwner;

        emit OwnershipTransferred(previousOwner, _newOwner);
    }

    // Helper function to count unique donors
    function getDonorCount() internal view returns (uint256) {
        uint256 count = 0;
        for (uint256 i = 0; i < donations.length; i++) {
            bool isUnique = true;
            for (uint256 j = 0; j < i; j++) {
                if (donations[i].donor == donations[j].donor) {
                    isUnique = false;
                    break;
                }
            }
            if (isUnique) {
                count++;
            }
        }
        return count;
    }

    // Get contract balance
    function getContractBalance() external view returns (uint256) {
        return address(this).balance;
    }

    // Get total number of donations
    function getTotalDonations() external view returns (uint256) {
        return donations.length;
    }

    // Fallback function to receive Ether
    receive() external payable {
        donations.push(Donation({
            donor: msg.sender,
            amount: msg.value,
            timestamp: block.timestamp,
            message: "Direct transfer"
        }));

        donorTotalContributions[msg.sender] += msg.value;
        totalDonationsReceived += msg.value;

        emit DonationReceived(msg.sender, msg.value, "Direct transfer", block.timestamp);
    }
}
