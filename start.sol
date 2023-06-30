pragma solidity ^0.8.0;

contract PeerToPeerLending {
    struct Loan {
        uint256 amount;
        uint256 interestRate;
        uint256 term;
        uint256 startTime;
        uint256 endTime;
        bool isApproved;
        bool isCompleted;
        address borrower;
        address lender;
        mapping(uint256 => uint256) repayments; // Mapping of repayment amounts by time
        uint256 totalRepayments;
    }
    
    mapping(uint256 => Loan) public loans; // Mapping of loans by ID
    uint256 public loanCounter;
    
    function createLoan(uint256 amount, uint256 interestRate, uint256 term) external {
        require(msg.sender != address(0), "Invalid address.");
        require(amount > 0, "Amount must be greater than 0.");
        require(interestRate > 0 && interestRate < 100, "Interest rate must be between 0 and 100.");
        require(term > 0, "Term must be greater than 0.");
        
        Loan storage loan = loans[loanCounter];
        loan.amount = amount;
        loan.interestRate = interestRate;
        loan.term = term;
        loan.startTime = block.timestamp;
        loan.endTime = block.timestamp + term;
        loan.borrower = msg.sender;
        
        loanCounter++;
    }
    
    function approveLoan(uint256 loanId) external {
        Loan storage loan = loans[loanId];
        
        require(msg.sender != address(0), "Invalid address.");
        require(msg.sender != loan.borrower, "Lenders cannot lend to themselves.");
        require(!loan.isApproved, "Loan has already been approved.");
        require(!loan.isCompleted, "Loan has already been completed.");
        require(block.timestamp < loan.endTime, "Loan has expired.");
        
        loan.isApproved = true;
        loan.lender = msg.sender;
    }
    
    function repayLoan(uint256 loanId) external payable {
        Loan storage loan = loans[loanId];
        
        require(msg.sender != address(0), "Invalid address.");
        require(loan.isApproved, "Loan has not been approved.");
        require(!loan.isCompleted, "Loan has already been completed.");
        require(block.timestamp < loan.endTime, "Loan has expired.");
        require(msg.value > 0, "Repayment amount must be greater than 0.");
        
        uint256 amountRemaining = loan.amount - loan.totalRepayments;
        uint256 repaymentAmount = msg.value;
        
        // Check if repayment amount exceeds remaining loan amount and adjust repayment amount accordingly
        if (repaymentAmount > amountRemaining) {
            repaymentAmount = amountRemaining;
        }
        
        loan.repayments[block.timestamp] += repaymentAmount;
        loan.totalRepayments += repaymentAmount;
        
        // If loan has been fully repaid, transfer remaining balance to borrower and mark loan as completed
        if (loan.totalRepayments == loan.amount) {
            loan.isCompleted = true;
            loan.lender.transfer(amountRemaining);
        }
        // Otherwise, transfer repayment amount to lender
        else {
            loan.lender.transfer(repaymentAmount);
        }
    }
}


