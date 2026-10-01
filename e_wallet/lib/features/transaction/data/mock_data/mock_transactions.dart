import '../../domain/models/transaction.dart';

const mockTransactions = <TransactionModel>[
  TransactionModel(
    id: 'NP-85A3F21',
    name: 'Thida Meas',
    amount: 250,
    date: 'Today · 10:42',
    category: TransactionCategory.received,
  ),
  TransactionModel(
    id: 'NP-B13D9C0',
    name: 'Netflix',
    amount: -15.49,
    date: 'Today · 08:15',
    category: TransactionCategory.sent,
  ),
  TransactionModel(
    id: 'NP-0D5E721',
    name: 'Cash deposit',
    amount: 600,
    date: 'Yesterday · 16:30',
    category: TransactionCategory.deposit,
  ),
  TransactionModel(
    id: 'NP-1A09F84',
    name: 'Sokha Keo',
    amount: -82.75,
    date: 'Yesterday · 12:10',
    category: TransactionCategory.sent,
  ),
  TransactionModel(
    id: 'NP-C7B92FE',
    name: 'Withdraw to ABA',
    amount: -300,
    date: 'Oct 03 · 09:30',
    category: TransactionCategory.withdraw,
  ),
];
