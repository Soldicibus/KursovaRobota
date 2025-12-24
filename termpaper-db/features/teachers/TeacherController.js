import TeacherService from "./TeacherService.js";
import { bouncer } from "../../lib/db-helpers/bouncer.js";

class TeacherController {
  static async getAllTeachers(req, res, next) {
    await bouncer(req, res, async (db) => {
      const result = await TeacherService.getAllTeachers(db);
      return result;
    });
  }

  static async getTeacherById(req, res, next) {
    await bouncer(req, res, async (db) => {
      const { id } = req.params;

      if (!id) {
        throw new Error("Teacher ID is required");
      }

      const result = await TeacherService.getTeacherById(id, db);
      return result;
    });
  }

  static async getTeachersWithClasses(req, res, next) {
    await bouncer(req, res, async (db) => {
      const { id } = req.params;

      if (id === undefined || id === null || String(id).trim() === "") {
        throw new Error("Teacher ID is required");
      }

      const teacherId = Number(id);
      if (!Number.isInteger(teacherId) || teacherId <= 0) {
        throw new Error("Teacher ID must be a positive integer");
      }

      const result = await TeacherService.getTeachersWithClasses(teacherId, db);
      return result;
    });
  }

  static async getTeachersWithClassesByName(req, res, next) {
    await bouncer(req, res, async (db) => {
      const { className } = req.params;

      if (!className) {
        throw new Error("Class name is required");
      }

      const result = await TeacherService.getTeachersWithClassesByName(className, db);
      return result;
    });
  }

  static async getTeacherSalary(req, res, next) {
    await bouncer(req, res, async (db) => {
      const { teacherId, fromDate, toDate } = req.params;

      if (!teacherId || !fromDate || !toDate) {
        throw new Error("teacherId, fromDate, and toDate are required");
      }

      const result = await TeacherService.getTeacherSalary(
        teacherId,
        fromDate,
        toDate,
        db,
      );
      return result;
    });
  }

  static async createTeacher(req, res, next) {
    await bouncer(req, res, async (db) => {
  const { name, surname, patronym, phone } = req.body;

      if (!name || !surname || !patronym || !phone) {
        throw new Error("name, surname, patronym, and phone are required");
      }

      const result = await TeacherService.createTeacher(
        name,
        surname,
        patronym,
        phone,
        db,
      );
      return result;
    });
  }

  static async updateTeacher(req, res, next) {
    await bouncer(req, res, async (db) => {
  const { id } = req.params;
  const { name, surname, patronym, phone } = req.body;

      if (!id || !name || !surname || !patronym || !phone) {
        throw new Error("id, name, surname, patronym, and phone are required");
      }

      const result = await TeacherService.updateTeacher(
        id,
        name,
        surname,
        patronym,
        phone,
        db,
      );
      return result;
    });
  }

  static async deleteTeacher(req, res, next) {
    await bouncer(req, res, async (db) => {
      const { id } = req.params;

      if (!id) {
        throw new Error("Teacher ID is required");
      }

      const result = await TeacherService.deleteTeacher(id, db);
      return result;
    });
  }
}

export default TeacherController;
