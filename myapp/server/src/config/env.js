const { config } = require("dotenv");

config();

const DB_NAME = process.env.DB_NAME;
const DB_HOST = process.env.DB_HOST;
const DB_PORT = process.env.DB_PORT;
const DB_USER = process.env.DB_USER;
const DB_PASSWORD = process.env.DB_PASSWORD;
const DB_SSL_MODE = process.env.DB_SSL_MODE;
const DB_CONNECTION_LIMIT = process.env.DB_CONNECTION_LIMIT;
const secret_key = process.env.SECRET_KEY;

module.exports = {
  DB_NAME,
  DB_HOST,
  DB_PORT,
  DB_USER,
  DB_PASSWORD,
  DB_SSL_MODE,
  DB_CONNECTION_LIMIT,
  secret_key,
};
