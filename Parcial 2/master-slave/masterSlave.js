const postgres = require("postgres");

const master = postgres("postgres://user:password@localhost:5432/postgres");
const replica1 = postgres("postgres://user:password@localhost:5433/postgres");
const replica2 = postgres("postgres://user:password@localhost:5434/postgres");

const sleep = (ms) => new Promise((res) => setTimeout(res, ms));

const NEW_USER_ID=300003;

const runReplicationTest = async () => {
  const now = new Date();

  const insertQuery = `
    INSERT INTO users (user_id, first_name, last_name, business_name, business_type, creation_date, email, phone_number)
    VALUES (${NEW_USER_ID}, 'Replica', 'Tester', 'Test Inc.', 1, '${now.toISOString().slice(0, 10)}', 'replica@test.com', 123456789);
  `;

  try {
    console.log("Inserting into master...");
    await master.unsafe(insertQuery);
    console.log("Inserted. Waiting for replication...");

    await sleep(3000);

    console.log("Reading from replica 1:");
    const result1 = await replica1`SELECT * FROM users WHERE user_id = ${NEW_USER_ID}`;
    console.log(result1);

    console.log("Reading from replica 2:");
    const result2 = await replica2`SELECT * FROM users WHERE user_id = ${NEW_USER_ID}`;
    console.log(result2);
  } catch (err) {
    console.error("Error:", err);
  }
};

runReplicationTest();
