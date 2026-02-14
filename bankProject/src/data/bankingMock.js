export const userProfile = {
  name: "John Anderson",
  email: "john.anderson@email.com",
  phone: "+1 (555) 123-4567",
  tier: "Quantum Premier",
}

export const accounts = [
  {
    id: "acc-001",
    name: "Everyday Checking",
    number: "**** 4521",
    type: "Checking",
    balance: 12458.92,
    status: "Active",
  },
  {
    id: "acc-002",
    name: "High-Yield Savings",
    number: "**** 7890",
    type: "Savings",
    balance: 45230.85,
    status: "Active",
  },
  {
    id: "acc-003",
    name: "Fixed Deposit",
    number: "**** 3214",
    type: "Fixed",
    balance: 100000.0,
    status: "Active",
  },
]

export const transactions = [
  {
    id: "txn-001",
    name: "Salary Deposit",
    date: "Feb 13, 2026",
    category: "Income",
    amount: 8500.0,
    type: "credit",
  },
  {
    id: "txn-002",
    name: "Rent Payment",
    date: "Feb 12, 2026",
    category: "Housing",
    amount: -2500.0,
    type: "debit",
  },
  {
    id: "txn-003",
    name: "Amazon Purchase",
    date: "Feb 11, 2026",
    category: "Shopping",
    amount: -156.43,
    type: "debit",
  },
  {
    id: "txn-004",
    name: "Electricity Bill",
    date: "Feb 10, 2026",
    category: "Utilities",
    amount: -89.5,
    type: "debit",
  },
  {
    id: "txn-005",
    name: "Investment Return",
    date: "Feb 09, 2026",
    category: "Investment",
    amount: 450.0,
    type: "credit",
  },
]

export const beneficiaries = [
  {
    id: "ben-01",
    name: "Olivia Parker",
    bank: "Crescent Bank",
    account: "**** 2240",
  },
  {
    id: "ben-02",
    name: "Northline Utilities",
    bank: "Citywide Credit",
    account: "**** 1108",
  },
  {
    id: "ben-03",
    name: "Summit Rentals",
    bank: "Summit Bank",
    account: "**** 5512",
  },
]

export const bills = [
  {
    id: "bill-001",
    name: "Electricity",
    due: "Feb 20, 2026",
    amount: 145.0,
    status: "Due Soon",
  },
  {
    id: "bill-002",
    name: "Internet",
    due: "Feb 22, 2026",
    amount: 85.99,
    status: "Scheduled",
  },
  {
    id: "bill-003",
    name: "Mortgage",
    due: "Mar 01, 2026",
    amount: 2240.0,
    status: "Scheduled",
  },
]

export const cards = [
  {
    id: "card-001",
    name: "Quantum Platinum",
    number: "**** 9832",
    limit: 25000,
    used: 3420.5,
    status: "Active",
  },
  {
    id: "card-002",
    name: "Travel Rewards",
    number: "**** 1144",
    limit: 12000,
    used: 8640.1,
    status: "Frozen",
  },
]

export const stats = [
  {
    id: "stat-1",
    label: "Total Balance",
    value: "$182,450.32",
    trend: "+2.4%",
  },
  {
    id: "stat-2",
    label: "Monthly Income",
    value: "$8,950.00",
    trend: "+1.2%",
  },
  {
    id: "stat-3",
    label: "Monthly Spend",
    value: "$5,234.67",
    trend: "-3.1%",
  },
  {
    id: "stat-4",
    label: "Rewards Points",
    value: "28,640",
    trend: "+560",
  },
]
