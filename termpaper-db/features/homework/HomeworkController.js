import HomeworkService from "./HomeworkService.js";
import bouncer from "../../lib/db-helpers/bouncer.js";

class HomeworkController {
  static async getAllHomework(req, res, next) {
    await bouncer(req, res, async (db) => {
      const result = await HomeworkService.getAllHomework(db);
      return result;
    });
  }

  static async getHomeworkById(req, res, next) {
    await bouncer(req, res, async (db) => {
      const { id } = req.params;

      if (!id) {
        throw new Error("Homework ID is required");
      }

      const result = await HomeworkService.getHomeworkById(id, db);
      return result;
    });
  }

  static async getHomeworkByStudentOrClass(req, res, next) {
    await bouncer(req, res, async (db) => {
      const { studentId } = req.params;

      if (!studentId) {
        throw new Error("Student ID is required");
      }

      const result = await HomeworkService.getHomeworkByStudentOrClass(studentId, db);
      return result;
    });
  }

  static async getHomeworkForTomorrow(req, res, next) {
    await bouncer(req, res, async (db) => {
      const result = await HomeworkService.getHomeworkForTomorrow(db);
      return result;
    });
  }

  static async createHomework(req, res, next) {
    await bouncer(req, res, async (db) => {
      const { name, teacherId, lessonId, dueDate, description, className } = req.body;

      if (!name || !teacherId || !lessonId || !dueDate || !description || !className) {
        throw new Error("name, teacherId, lessonId, dueDate, description, and className are required");
      }

      const result = await HomeworkService.createHomework(
        name,
        teacherId,
        lessonId,
        dueDate,
        description,
        className,
        db,
      );
      return result;
    });
  }

  static async updateHomework(req, res, next) {
    await bouncer(req, res, async (db) => {
      const { id } = req.params;
      const { name, teacherId, lessonId, dueDate, description, className } = req.body;

      if (!id || !name || !teacherId || !lessonId || !dueDate || !description || !className) {
        throw new Error("id, name, teacherId, lessonId, dueDate, description, and className are required");
      }

      const result = await HomeworkService.updateHomework(
        id,
        name,
        teacherId,
        lessonId,
        dueDate,
        description,
        className,
        db,
      );
      return result;
    });
  }

  static async deleteHomework(req, res, next) {
    await bouncer(req, res, async (db) => {
      const { id } = req.params;

      if (!id) {
        throw new Error("Homework ID is required");
      }

      const result = await HomeworkService.deleteHomework(id, db);
      return result;
    });
  }
}

export default HomeworkController;

