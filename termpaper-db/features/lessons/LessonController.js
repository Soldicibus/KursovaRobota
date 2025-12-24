import LessonService from "./LessonService.js";
import bouncer from "../../lib/db-helpers/bouncer.js";

class LessonController {
  static async getAllLessons(req, res, next) {
    await bouncer(req, res, async (db) => {
      const result = await LessonService.getAllLessons(db);
      return result;
    });
  }

  static async getLessonById(req, res, next) {
    await bouncer(req, res, async (db) => {
      const { id } = req.params;

      if (!id) {
        throw new Error("Lesson ID is required");
      }

      const result = await LessonService.getLessonById(id, db);
      return result;
    });
  }

  static async getLessonByName(req, res, next) {
    await bouncer(req, res, async (db) => {
      const { name } = req.params;

      if (!name) {
        throw new Error("Lesson name is required");
      }

      const result = await LessonService.getLessonByName(name, db);
      return result;
    });
  }

  static async createLesson(req, res, next) {
    await bouncer(req, res, async (db) => {
      const { name, className, subjectId, materialId, teacherId, date } =
        req.body;

      if (
        !name ||
        !className ||
        !subjectId ||
        !materialId ||
        !teacherId ||
        !date
      ) {
        throw new Error(
          "name, className, subjectId, materialId, teacherId, and date are required",
        );
      }

      const result = await LessonService.createLesson(
        name,
        className,
        subjectId,
        materialId,
        teacherId,
        date,
        db,
      );
      return result;
    });
  }

  static async updateLesson(req, res, next) {
    await bouncer(req, res, async (db) => {
      const { id } = req.params;
      const { name, className, subjectId, materialId, teacherId, date } =
        req.body;

      if (
        !id ||
        !name ||
        !className ||
        !subjectId ||
        !materialId ||
        !teacherId ||
        !date
      ) {
        throw new Error(
          "id, name, className, subjectId, materialId, teacherId, and date are required",
        );
      }

      const result = await LessonService.updateLesson(
        id,
        name,
        className,
        subjectId,
        materialId,
        teacherId,
        date,
        db,
      );
      return result;
    });
  }

  static async deleteLesson(req, res, next) {
    await bouncer(req, res, async (db) => {
      const { id } = req.params;

      if (!id) {
        throw new Error("Lesson ID is required");
      }

      const result = await LessonService.deleteLesson(id, db);
      return result;
    });
  }
}

export default LessonController;

