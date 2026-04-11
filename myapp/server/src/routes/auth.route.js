const { Router } = require("express");
const { signup, login, getUser } = require("../controller/auth.controller");

const authRouter = Router();
authRouter.post("/register", signup);
authRouter.post("/login", login);
authRouter.get("/getuser/:id", getUser);

module.exports = {
  authRouter,
};
