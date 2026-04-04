const { Router } = require("express");
const {
  createReminder,
  getReminders,
  getReminderById,
  updateReminder,
  deleteReminder,
} = require("../controller/reminder.controller");
const { authenticate } = require("../middleware/isAuthenticated");
const reminderRouter = Router();
reminderRouter.post("/create", authenticate, createReminder);
reminderRouter.get("/getAll", authenticate, getReminders);
reminderRouter.get("/getById/:id", authenticate, getReminderById);
reminderRouter.patch("/update/:id", authenticate, updateReminder);
reminderRouter.delete("/delete/:id", authenticate, deleteReminder);

module.exports = {
  reminderRouter,
};
