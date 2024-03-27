# Additional API Specification
## (#bank-transaction-code) Bank Transaction Code
**Transaction Type**              | **Transaction Code** 
-----------------------------------|----------------------
 Authorization Accepted / Rejected      | PMNT-MCRD-UPCT       
 Authorization Reversal / Expired       | PMNT-MCRD-DAJT       
 Cash26 Deposit                         | PMNT-CNTR-CDPT       
 Cash26 Withdrawal                      | PMNT-CNTR-CWDL       
 Credit Transfer                        | PMNT-RCDT-ESCT       
 Direct Debit                           | PMNT-IDDT-ESDD       
 SEPA Bank Transfer                     | PMNT-ICDT-ESCT       
 Direct Debit Reversal                  | PMNT-IDDT-PRDD       
 N26 Moneybeam                          | PMNT-ICDT-BOOK       
 Internal Debit Transfer                | ACMT-OPCL-ACCC       
 Presentment Refund                     | PMNT-MCRD-OTHR       
 Presentment                            | PMNT-CCRD-POSD       
 Remittance Transfer (Wise)             | PMNT-RCDT-XBCT       
 N26 Fees                               | PMNT-MDOP-FEES       
 Reward Transfer                        | PMNT-RCDT-ESCT
 ATM Withdrawal                         | PMNT-CCRD-CWDL
 Mastercard MoneySend                   | PMNT-RRCT-CAJT
 Mastercard MoneySend Reversal          | PMNT-RRCT-RPCR
 N26 Savings Account Incoming Interest  | PMNT-MCOP-INTR
 N26 Savings Account Outgoing Tax       | PMNT-MDOP-TAXE
 Others                                 | ACMT-OTHR-OTHR
