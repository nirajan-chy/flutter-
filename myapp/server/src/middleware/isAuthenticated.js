const { secret_key } = require("../config/env");

const User = require("../models/auth/auth.model");

const jwt = require("jsonwebtoken");

const authenticate = async (req, res, next) => {
  try {
    const authHeader = req.headers.authorization;

    if (!authHeader || !authHeader.startsWith("Bearer ")) {
      return res.status(401).json({
        success: false,
        message: "No token provided",
      });
    }

    const token = authHeader.split(" ")[1];

    const decoded = jwt.verify(token, secret_key);

    const user = await User.findByPk(decoded.id);

    if (!user) {
      return res.status(401).json({
        success: false,
        message: "Invalid token (user not found)",
      });
    }

    req.user = user;

    next();
  } catch (error) {
    console.error("Auth Error:", error);
    return res.status(401).json({
      success: false,
      message: "Unauthorized",
    });
  }
};

module.exports = {
  authenticate,
};
