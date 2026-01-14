import TimetableService from "./TimetableService.js";
import bouncer from "../../lib/db-helpers/bouncer.js";

class TimetableController {
  static async getAllTimetables(req, res, next) {
    await bouncer(req, res, async (db) => {
      const result = await TimetableService.getAllTimetables(db);
      return result;
    });
  }

  static async getTimetableById(req, res, next) {
    await bouncer(req, res, async (db) => {
      const { id } = req.params;

      if (!id) {
        throw new Error("Timetable ID is required");
      }

      const result = await TimetableService.getTimetableById(id, db);
      return result;
    });
  }

  static async createTimetable(req, res, next) {
    await bouncer(req, res, async (db) => {
      const { name, class_name } = req.body;

      if (!name || !class_name) {
        throw new Error("name and class_name are required");
      }

      const result = await TimetableService.createTimetable(name, class_name, db);
      return result;
    });
  }

  static async updateTimetable(req, res, next) {
    await bouncer(req, res, async (db) => {
      const { id } = req.params;
      const { name, class_name } = req.body;

      if (!id || !name || !class_name) {
        throw new Error("id, name, and class_name are required");
      }

      const result = await TimetableService.updateTimetable(id, name, class_name, db);
      return result;
    });
  }

  static async deleteTimetable(req, res, next) {
    await bouncer(req, res, async (db) => {
      const { id } = req.params;

      if (!id) {
        throw new Error("Timetable ID is required");
      }

      const result = await TimetableService.deleteTimetable(id, db);
      return result;
    });
  }

  static async getWeeklyTimetable(req, res, next) {
    await bouncer(req, res, async (db) => {
      const { id } = req.params;

      if (!id) {
        throw new Error("Timetable ID is required");
      }
      console.log("[controller] getWeeklyTimetable id=", id);
      const result = await TimetableService.getWeeklyTimetable(id, db);
      return result;
    });
  }

  static async getTimetableByStudentId(req, res, next) {
    await bouncer(req, res, async (db) => {
      const { id } = req.params;
      if (!id) throw new Error("Student ID is required");
      const result = await TimetableService.getTimetableByStudentId(id, db);
      return result;
    });
  }
}

export default TimetableController;

