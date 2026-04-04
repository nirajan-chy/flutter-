const jwt = require("jsonwebtoken");
const { secret_key } = require("../config/env");

const generateToken = user => {
  return jwt.sign(
    {
      id: user.id,
      email: user.email,
      role: user.role,
    },
    secret_key,
    {
      expiresIn: "7d",
    },
  );
};

module.exports = {
  generateToken,
};
