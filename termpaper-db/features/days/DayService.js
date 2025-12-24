import DayModule from "../../lib/models/DayModel.js";
import pool from "../../lib/db.js";

class DayService {
  static async getAllDays(db = pool) {
    try {
      const days = await DayModule.findAll(db);
      return { days };
    } catch (error) {
      console.error("Service Error in getAllDays:", error.message);
      throw error;
    }
  }

  static async getDayById(dayId, db = pool) {
    try {
      const day = await DayModule.findById(dayId, db);
      if (!day) {
        throw new Error(`Day with ID ${dayId} not found`);
      }
      return { day };
    } catch (error) {
      console.error("Service Error in getDayById:", error.message);
      throw error;
    }
  }

  static async createDay(subjectID, timetableId, dayTime, dayWeekday, db = pool) {
    try {
      const dayId = await DayModule.create(subjectID, timetableId, dayTime, dayWeekday, db);
      return { dayId, message: "Day created successfully" };
    } catch (error) {
      console.error("Service Error in createDay:", error.message);
      throw error;
    }
  }

  static async updateDay(dayId, subjectId, timetableId, dayTime, dayWeekday, db = pool) {
    try {
      await DayModule.update(dayId, subjectId, timetableId, dayTime, dayWeekday, db);
      return { message: "Day updated successfully" };
    } catch (error) {
      console.error("Service Error in updateDay:", error.message);
      throw error;
    }
  }

  static async deleteDay(dayId, db = pool) {
    try {
      await DayModule.delete(dayId, db);
      return { message: `Day ${dayId} deleted successfully` };
    } catch (error) {
      console.error("Service Error in deleteDay:", error.message);
      throw error;
    }
  }
}

export default DayService;


