const {
  DB_HOST,
  DB_NAME,
  DB_PASSWORD,
  DB_PORT,
  DB_USER,
  DB_SSL_MODE,
} = require("./env");

const { Sequelize } = require("sequelize");

const sequelize = new Sequelize(DB_NAME, DB_USER, DB_PASSWORD, {
  host: DB_HOST,
  port: DB_PORT,
  dialect: "postgres",
  logging: false,

  dialectOptions: {
    ssl:
      DB_SSL_MODE === "require"
        ? {
            require: true,
            rejectUnauthorized: false, // set true if using CA cert
          }
        : false,
  },
});

const connectDB = async () => {
  try {
    await sequelize.authenticate();
    console.log("PostgreSQL connected successfully");
  } catch (error) {
    console.error("Connection failed:", error);
    process.exit(1);
  }
};

module.exports = {
  connectDB,
  sequelize,
};
