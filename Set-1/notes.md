

## 1. READ COMMITTED and SNAPSHOT Isolation

### READ COMMITTED
- Prevents dirty reads by allowing only committed data to be read.
- Another transaction can update and commit data between two SELECT statements.
- Repeated reads may return different values (non-repeatable reads).

### SNAPSHOT
- Provides a consistent view of committed data from the beginning of the transaction.
- Repeated reads return the same data even if another transaction commits an update.
- Uses row versioning and must be enabled at the database level.

### Two-Session Demonstration

| READ COMMITTED | SNAPSHOT |
|---|---|
| Session A reads the original balance. | Session A reads the original balance. |
| Session B updates and commits the balance. | Session B updates and commits the balance. |
| Session A's second read shows the updated balance. | Session A's second read shows the original balance. |

## 2. MongoDB Multi-Document Transaction

MongoDB performs funds transfers using sessions and multi-document transactions.

**Transaction steps:**
1. Start a session using `startSession()`.
2. Start the transaction using `withTransaction()`.
3. Debit the sender using `updateOne()`.
4. Credit the receiver using `updateOne()`.
5. Commit if both operations succeed.
6. Abort if any operation fails.

This ensures that both account updates succeed together or neither is committed.

**Requirement:** MongoDB multi-document transactions require a replica set or sharded cluster.

## 3. Cost of MongoDB Transactions

- **Performance:** Transactions introduce additional processing time.
- **Resources:** They consume additional memory and database resources.
- **Write conflicts:** Concurrent transactions may cause conflicts and retries.
- **Storage:** Transaction consistency requires maintaining additional version and transaction information.
- **Complexity:** Applications must handle failures, retries and timeouts.

**Conclusion:** MongoDB transactions are useful for bank transfers involving multiple documents, but should be kept short to reduce performance and resource overhead.
