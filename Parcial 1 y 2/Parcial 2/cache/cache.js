const { createClient } = require("redis");
const postgres = require("postgres");
const { MongoClient } = require("mongodb");

const redisClient = createClient({
  url: "redis://:eYVX7EwVmmxKPCDmwMtyKVge8oLd2t81@localhost:6379",
});
redisClient.connect().catch(console.error);

const sql = postgres("postgres://admin:admin@localhost:5432/cowork");

const mongoClient = new MongoClient("mongodb://admin:secret@localhost:27017");
const mongoDB = mongoClient.db("cowork_fase2");
const stationSchedules = mongoDB.collection("station_schedules");

const USER_HASH_KEY = "user";
const SCHEDULE_KEY = "station_schedules";

const getUserFromDB = async (id) => {
  const [user] = await sql`
    SELECT * FROM users WHERE user_id = ${id}
  `;
  return user;
};

const getUser = async (id) => {
  const redisKey = `${USER_HASH_KEY}:${id}`;
  const cached = await redisClient.hGetAll(redisKey);

  if (Object.keys(cached).length > 0) {
    console.log("From Redis");
    return cached;
  }

  const user = await getUserFromDB(id);
  if (user) {
    const mapping = Object.fromEntries(
      Object.entries(user).map(([k, v]) => [k, String(v)])
    );

    await redisClient.hSet(redisKey, mapping);
    await redisClient.expire(redisKey, 3600); // 1 hr TTL
  }

  return user;
};

const setReserva = async (data) => {
  await sql`
    UPDATE reservas SET
      user_id = ${data.user_id},
      estacion_id = ${data.estacion_id},
      start_date = ${data.start_date},
      finish_date = ${data.finish_date},
      state = ${data.state},
      reserva_type = ${data.type}
    WHERE reserva_id = ${data.reserva_id}
  `;

  const redisKey = `${RESERVATION_HASH_KEY}:${data.reserva_id}`;

  const mapping = Object.fromEntries(
    Object.entries(data).map(([k, v]) => [k, String(v)])
  );

  await redisClient.hSet(redisKey, mapping);
  await redisClient.expire(redisKey, 300); // 5 min TTL
};

const getSchedulesFromDB = async () => {
  return await stationSchedules.find().toArray();
};

const getSchedules = async () => {
  const cached = await redisClient.get(SCHEDULE_KEY);
  if (cached) {
    console.log("From Redis");
    return JSON.parse(cached);
  }

  const schedules = await getSchedulesFromDB();
  await redisClient.setEx(SCHEDULE_KEY, 3600, JSON.stringify(schedules)); // 1 hour TTL
  return schedules;
};

(async () => {
  try {
    await mongoClient.connect();

    console.log("\nUsuario: ")

    const user = await getUser(1);
    console.log(user);
    console.log(await getUser(1));


    console.log("\nHorarios:");
    const schedules = await getSchedules();
    console.log(schedules);
    console.log(await getSchedules());
  } catch (err) {
    console.error(err);
  } finally {
    await mongoClient.close();
    await redisClient.quit();
  }
})();
