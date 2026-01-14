import StudentDataService from "./StudentDataService.js";
import bouncer from "../../lib/db-helpers/bouncer.js";

class StudentDataController {
  static async getAllStudentData(req, res, next) {
    await bouncer(req, res, async (db) => {
      const result = await StudentDataService.getAllStudentData(db);
      return result;
    });
  }

  static async getStudentDataById(req, res, next) {
    await bouncer(req, res, async (db) => {
      const { id } = req.params;

      if (!id) {
        throw new Error("Student Data ID is required");
      }

      const result = await StudentDataService.getStudentDataById(id, db);
      return result;
    });
  }

  static async createStudentData(req, res, next) {
    await bouncer(req, res, async (db) => {
      const { journalId, studentId, lesson, mark, status, note } = req.body;

      if (!journalId || !studentId || !lesson) {
        throw new Error(
          "journalId, studentId, and lesson are required",
        );
      }

      const result = await StudentDataService.createStudentData(
        journalId,
        studentId,
        lesson,
        mark || null,
        status,
        note || null,
        db,
      );
      return result;
    });
  }

  static async updateStudentData(req, res, next) {
    await bouncer(req, res, async (db) => {
      const { id } = req.params;
      const { journalId, studentId, lesson, mark, status, note } = req.body;

      if (
        !id ||
        !journalId ||
        !studentId ||
        !lesson
      ) {
        throw new Error(
          "id, journalId, studentId, and lesson are required",
        );
      }

      const result = await StudentDataService.updateStudentData(
        id,
        journalId,
        studentId,
        lesson,
        mark || null,
        status,
        note || null,
        db,
      );
      return result;
    });
  }

  static async deleteStudentData(req, res, next) {
    await bouncer(req, res, async (db) => {
      const { id } = req.params;

      if (!id) {
        throw new Error("Student Data ID is required");
      }

      const result = await StudentDataService.deleteStudentData(id, db);
      return result;
    });
  }

  static async getStudentDataMarks7d(req, res, next) {
    await bouncer(req, res, async (db) => {
      const { studentId } = req.params;
      if (!studentId) throw new Error("Student ID is required");
      const result = await StudentDataService.getStudentDataMarks7d(studentId, db);
      return result;
    });
  }
}

export default StudentDataController;

