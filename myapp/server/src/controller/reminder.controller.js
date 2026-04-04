const { Reminder } = require("../models/reminder.model");

const createReminder = async (req, res) => {
  try {
    const {
      title,
      description,
      time,
      repeat,
      repeatDays,
      timezone,
      snoozeMinutes,
    } = req.body;

    if (!title || !time) {
      return res.status(400).json({
        success: false,
        message: "Title and time are required",
      });
    }

    const reminder = await Reminder.create({
      userId: req.user.id,
      title,
      description,
      time,
      repeat,
      repeatDays,
      timezone,
      snoozeMinutes,
    });

    return res.status(201).json({
      success: true,
      message: "Reminder created",
      data: reminder,
    });
  } catch (error) {
    console.error("Create Reminder Error:", error);
    return res.status(500).json({
      success: false,
      message: "Failed to create reminder",
    });
  }
};

const getReminders = async (req, res) => {
  try {
    const reminders = await Reminder.findAll({
      where: { userId: req.user.id },
      order: [["time", "ASC"]],
    });
    console.log(reminders);

    return res.status(200).json({
      success: true,
      data: reminders,
    });
  } catch (error) {
    console.error("Get Reminders Error:", error);
    return res.status(500).json({
      success: false,
      message: error.message,
    });
  }
};

const getReminderById = async (req, res) => {
  try {
    const { id } = req.params;

    const reminder = await Reminder.findOne({
      where: { id, userId: req.user.id },
    });

    if (!reminder) {
      return res.status(404).json({
        success: false,
        message: "Reminder not found",
      });
    }

    return res.status(200).json({
      success: true,
      data: reminder,
    });
  } catch (error) {
    console.error("Get Reminder Error:", error);
    return res.status(500).json({
      success: false,
      message: "Failed to fetch reminder",
    });
  }
};

const updateReminder = async (req, res) => {
  try {
    const { id } = req.params;

    const reminder = await Reminder.findOne({
      where: { id, userId: req.user.id },
    });

    if (!reminder) {
      return res.status(404).json({
        success: false,
        message: "Reminder not found",
      });
    }

    await reminder.update(req.body);

    return res.status(200).json({
      success: true,
      message: "Reminder updated",
      data: reminder,
    });
  } catch (error) {
    console.error("Update Reminder Error:", error);
    return res.status(500).json({
      success: false,
      message: "Failed to update reminder",
    });
  }
};

const deleteReminder = async (req, res) => {
  try {
    const { id } = req.params;

    const reminder = await Reminder.findOne({
      where: { id, userId: req.user.id },
    });

    if (!reminder) {
      return res.status(404).json({
        success: false,
        message: "Reminder not found",
      });
    }

    await reminder.destroy();

    return res.status(200).json({
      success: true,
      message: "Reminder deleted",
    });
  } catch (error) {
    console.error("Delete Reminder Error:", error);
    return res.status(500).json({
      success: false,
      message: "Failed to delete reminder",
    });
  }
};
module.exports = {
  createReminder,
  getReminders,
  getReminderById,
  updateReminder,
  deleteReminder,
};
