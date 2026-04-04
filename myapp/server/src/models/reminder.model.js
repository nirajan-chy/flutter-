const { DataTypes } = require("sequelize");

const { sequelize } = require("../config/postgres");



const Reminder = sequelize.define(
  "Reminder",
  {
    id: {
      type: DataTypes.UUID,
      defaultValue: DataTypes.UUIDV4,
      primaryKey: true,
    },

    userId: {
      type: DataTypes.UUID,
      allowNull: false,
    },

    title: {
      type: DataTypes.STRING,
      allowNull: false,
    },

    description: {
      type: DataTypes.TEXT,
      allowNull: true,
    },

    time: {
      type: DataTypes.DATE,
      allowNull: false,
    },

    repeat: {
      type: DataTypes.ENUM("none", "daily", "weekly"),
      defaultValue: "none",
    },

    repeatDays: {
      type: DataTypes.ARRAY(DataTypes.STRING), 
      allowNull: true,
    },

    timezone: {
      type: DataTypes.STRING,
      defaultValue: "UTC",
    },

    isActive: {
      type: DataTypes.BOOLEAN,
      defaultValue: true,
    },

    snoozeMinutes: {
      type: DataTypes.INTEGER,
      defaultValue: 5,
    },

    lastTriggeredAt: {
      type: DataTypes.DATE,
      allowNull: true,
    },
  },
  {
    tableName: "reminders",
    timestamps: true,
  },
);

module.exports = {
  Reminder
}
