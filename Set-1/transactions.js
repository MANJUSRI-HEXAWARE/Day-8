
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

### Step 3: Verify the balances


```javascript
db.accounts.find()
```





