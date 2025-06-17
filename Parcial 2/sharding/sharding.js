const postgres = require("postgres");

const sqlLaPaz = postgres(
  "postgres://postgres:lapazpass@localhost:5432/cowork",
  {
    host: "localhost",
    port: 5432,
    database: "cowork",
    username: "postgres",
    password: "lapazpass",
  }
);

const sqlCbba = postgres(
  "postgres://postgres:cbbapass@localhost:5433/cowork",
  {
    host: "localhost",
    port: 5433,
    database: "cowork",
    username: "postgres",
    password: "cbbapass",
  }
);

const getUsersLapaz = async () => {
  const users = await sqlLaPaz`SELECT user_id, first_name, last_name FROM users`;
  console.log("La Paz:", users);
  return users
};

const getUsersCbba = async () => {
  const users = await sqlCbba`SELECT user_id, first_name, last_name FROM users`;
  console.log("Cbba:", users);
};

const LA_PAZ = 'LP';
const COCHABAMBA = 'CBBA';


const insertUser = async (data) => {
  const query = (sql) => sql`
    INSERT INTO users (
      user_id,
      first_name,
      last_name,
      business_name,
      business_type,
      creation_date,
      email,
      phone_number
    ) VALUES (
      ${data.user_id},
      ${data.first_name},
      ${data.last_name},
      ${data.business_name},
      ${data.business_type},
      ${data.creation_date},
      ${data.email},
      ${data.phone_number}
    )
  `;

  if (data.city === LA_PAZ) {
    await query(sqlLaPaz);
  } else if (data.city === COCHABAMBA) {
    await query(sqlCbba);
  } else {
    const dbChoice = data.user_id % 2 === 0 ? sqlLaPaz : sqlCbba;
    await query(dbChoice);
  }
};

const rebeca = {
  city: 'LP',
  user_id: 1000002,
  first_name: 'Rebeca',
  last_name: 'Navarro',
  business_name: 'Wrebe teas',
  business_type: 1,
  creation_date: '2024-01-10',
  email: 'rebeca@gmail.com',
  phone_number: 123456789,
};

const hade = {
  city: 'SC',
  user_id: 1000003,
  first_name: 'Hade',
  last_name: 'Villegas',
  business_name: 'Ville guesas',
  business_type: 2,
  creation_date: '2024-03-22',
  email: 'hade@example.com',
  phone_number: 987654321,
};

const monse = {
  city: 'CBBA',
  user_id: 1000005,
  first_name: 'Monserrat',
  last_name: 'Del Pilar',
  business_name: 'Monse dillas',
  business_type: 3,
  creation_date: '2024-06-17',
  email: 'monse@example.com',
  phone_number: 555555555,
};

const deleteUsers = async () => {
  
  await sqlLaPaz`
  delete from reservas_salon_talleres;
  `
  await sqlLaPaz`
  delete from reservas;
  `  
  await sqlLaPaz`
  delete from payments;
  `  
  await sqlLaPaz`
  delete from users;
  ` 
  
  
  await sqlCbba`
  delete from reservas_salon_talleres;
  `
  await sqlCbba`
  delete from payments;
  `  
  await sqlCbba`
  delete from reservas;
  `  
  await sqlCbba`
  delete from users;
  `
  

}

const queries = async () => {
  await insertUser(rebeca);
  await insertUser(hade);
  await insertUser(monse);

  await getUsersLapaz();
  await getUsersCbba();
}

const main = async () => {
  await deleteUsers();

  queries();
}
main()
