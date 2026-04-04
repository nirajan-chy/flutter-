const { Router } = require("express");
const { signup, login } = require("../controller/auth.controller");

const authRouter = Router();
authRouter.post("/register", signup);
authRouter.post("/login", login);

module.exports = {
  authRouter,
};
