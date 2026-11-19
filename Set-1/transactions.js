# transaction.js

```javascript
const { MongoClient } = require("mongodb");

async function transferMoney() {

    const client = new MongoClient("YOUR_MONGODB_CONNECTION_STRING");

    try {

        await client.connect();

        const db = client.db("BankDB");
        const accounts = db.collection("accounts");

        const session = client.startSession();

        try {

            await session.withTransaction(async () => {

                // Debit sender
                const debit = await accounts.updateOne(
                    {
                        accountNumber: "101",
                        status: "ACTIVE",
                        balance: { $gte: 5000 }
                    },
                    {
                        $inc: { balance: -5000 }
                    },
                    { session }
                );

                if (debit.matchedCount !== 1) {
                    throw new Error("Insufficient balance or inactive sender");
                }

                // Credit receiver
                const credit = await accounts.updateOne(
                    {
                        accountNumber: "102",
                        status: "ACTIVE"
                    },
                    {
                        $inc: { balance: 5000 }
                    },
                    { session }
                );

                if (credit.matchedCount !== 1) {
                    throw new Error("Receiver account not found or inactive");
                }

                console.log("Transfer operations completed.");

            });

            console.log("Transaction committed successfully.");

        } finally {

            await session.endSession();

        }

    } catch (error) {

        console.log("Transaction failed:", error.message);
        console.log("Transaction aborted.");

    } finally {

        await client.close();

    }
}

transferMoney();
```

Replace `YOUR_MONGODB_CONNECTION_STRING` with your actual connection string.

Run the file:

```bash
node transaction.js
```

### Step 3: Verify the balances

In `mongosh`, execute:

```javascript
db.accounts.find()
```

Expected result after a successful transfer:

| Account | Previous balance | New balance |
|---|---:|---:|
| Arun (101) | ₹50,000 | ₹45,000 |
| Priya (102) | ₹30,000 | ₹35,000 |

### How does the MongoDB transaction work?

1. `startSession()` creates a session.
2. `withTransaction()` starts a transaction.
3. `updateOne()` debits the sender.
4. Another `updateOne()` credits the receiver.
5. If both operations succeed, MongoDB commits the transaction.
6. If an operation fails, MongoDB aborts the transaction.

**Important:** MongoDB multi-document transactions require a replica set or sharded cluster. They won't work on a standalone MongoDB server.

---

## Part D – Cost of MongoDB transactions

**Question:** State the cost of using MongoDB multi-document transactions.

Write this explanation in your assignment:

<WritingBlock id="63114" variant="document">### Cost of MongoDB Multi-Document Transactions

MongoDB multi-document transactions provide atomicity, but they introduce additional overhead.

1. **Performance:** Transactions may take more time because multiple operations must be coordinated.
2. **Memory and resources:** Maintaining transaction information requires additional database resources.
3. **Concurrency:** Simultaneous transactions may cause write conflicts and retries.
4. **Storage:** MongoDB maintains data versions and transaction information to support consistency and durability.
5. **Complexity:** Developers must handle transaction failures, retries and timeouts.

**Conclusion:**

Multi-document transactions are useful when multiple documents must be updated together, such as bank funds transfers. However, they should be kept short and used only when necessary because they introduce additional performance and resource overhead.
