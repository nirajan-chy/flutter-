const cron = require("node-cron");
const { Op } = require("sequelize");
const { Reminder } = require("../models/reminder.model");

// ⏰ Run every minute
cron.schedule("* * * * *", async () => {
  console.log("⏳ Checking reminders...", new Date());

  const now = new Date(
    new Date().toLocaleString("en-US", {
      timeZone: "Asia/Kathmandu",
    }),
  );

  try {
    const reminders = await Reminder.findAll({
      where: {
        isActive: true,
        time: {
          [Op.lte]: now,
        },
      },
    });

    for (const reminder of reminders) {
      // ❗ prevent duplicate trigger within 1 min
      console.log("📌 Reminder found:", reminder.title, reminder.time);

      console.log(`🔔 TRIGGERING: ${reminder.title}`);
      if (
        reminder.lastTriggeredAt &&
        new Date(reminder.lastTriggeredAt).getTime() + 60000 > now.getTime()
      ) {
        continue;
      }

      // 🔔 Trigger (for now console)
      console.log(`🔔 Reminder: ${reminder.title}`);

      // ✅ update last triggered
      reminder.lastTriggeredAt = new Date();

      // 🔁 repeat logic
      if (reminder.repeat === "none") {
        reminder.isActive = false;
      }

      if (reminder.repeat === "daily") {
        const next = new Date(reminder.time);
        next.setDate(next.getDate() + 1);
        reminder.time = next;
      }

      if (reminder.repeat === "weekly") {
        const next = new Date(reminder.time);
        next.setDate(next.getDate() + 7);
        reminder.time = next;
      }

      await reminder.save();
    }
  } catch (error) {
    console.error("Cron Error:", error);
  }
});
