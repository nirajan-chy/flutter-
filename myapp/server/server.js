const express = require("express");
const { connectDB, sequelize } = require("./src/config/postgres");
const { authRouter } = require("./src/routes/auth.route");
const { reminderRouter } = require("./src/routes/reminder.route");

const app = express();
app.use(express.json());
require("./src/services/cron.service");

const port = 5000;
//auth
app.use("/auth", authRouter);
//reminder
app.use("/reminder", reminderRouter);

const bootstrap = async () => {
  try {
    await connectDB();
    await sequelize.sync();
    console.log("Database synchronized");

    app.listen(port, () => {
      console.log(`Server is running on port ${port}`);
    });
  } catch (error) {
    console.error("Startup failure:", error);
    process.exit(1);
  }
};

bootstrap();
