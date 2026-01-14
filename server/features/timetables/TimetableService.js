import TimetableModel from "../../lib/models/TimetabModel.js";
import pool from "../../lib/db.js";

class TimetableService {
  static async getAllTimetables(db = pool) {
    try {
      const timetables = await TimetableModel.find(db);
      return { timetables };
    } catch (error) {
      console.error("Service Error in getAllTimetables:", error.message);
      throw error;
    }
  }

  static async getTimetableById(timetableId, db = pool) {
    try {
      const timetable = await TimetableModel.findById(timetableId, db);
      if (!timetable) {
        throw new Error(`Timetable with ID ${timetableId} not found`);
      }
      return { timetable };
    } catch (error) {
      console.error("Service Error in getTimetableById:", error.message);
      throw error;
    }
  }

  static async createTimetable(name, class_name, db = pool) {
    try {
      const timetable = await TimetableModel.create(name, class_name, db);
      return { timetable, message: "Timetable created successfully" };
    } catch (error) {
      console.error("Service Error in createTimetable:", error.message);
      throw error;
    }
  }

  static async updateTimetable(timetableId, name, class_name, db = pool) {
    try {
      const timetable = await TimetableModel.update(timetableId, name, class_name, db);
      return { timetable, message: "Timetable updated successfully" };
    } catch (error) {
      console.error("Service Error in updateTimetable:", error.message);
      throw error;
    }
  }

  static async deleteTimetable(timetableId, db = pool) {
    try {
      const result = await TimetableModel.delete(timetableId, db);
      return result;
    } catch (error) {
      console.error("Service Error in deleteTimetable:", error.message);
      throw error;
    }
  }

  static async getWeeklyTimetable(timetableId, db = pool) {
    try {
      const timetable = await TimetableModel.weekById(timetableId, db);
      return { timetable: timetable || [] };
    } catch (error) {
      console.error("Service Error in getWeeklyTimetable:", error.message);
      throw error;
    }
  }

  static async getTimetableByStudentId(studentId, db = pool) {
    try {
      const timetable = await TimetableModel.findTimetablebyStudentId(studentId, db);
      return { timetable };
    } catch (error) {
      console.error("Service Error in getTimetableByStudentId:", error.message);
      throw error;
    }
  }
}

export default TimetableService;


