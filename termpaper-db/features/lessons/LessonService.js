import LessonModule from "../../lib/models/LessonModel.js";
import pool from "../../lib/db.js";

class LessonService {
  static async getAllLessons(db = pool) {
    try {
      const lessons = await LessonModule.findAll(db);
      return { lessons };
    } catch (error) {
      console.error("Service Error in getAllLessons:", error.message);
      throw error;
    }
  }

  static async getLessonById(lessonId, db = pool) {
    try {
      const lesson = await LessonModule.findById(lessonId, db);
      if (!lesson) {
        throw new Error(`Lesson with ID ${lessonId} not found`);
      }
      return { lesson };
    } catch (error) {
      console.error("Service Error in getLessonById:", error.message);
      throw error;
    }
  }

  static async getLessonByName(name, db = pool) {
    try {
      const lesson = await LessonModule.findByName(name, db);
      if (!lesson) {
        throw new Error(`Lesson with name ${name} not found`);
      }
      return { lesson };
    } catch (error) {
      console.error("Service Error in getLessonByName:", error.message);
      throw error;
    }
  }

  static async createLesson(
    name,
    className,
    subjectId,
    materialId,
    teacherId,
    date,
    db = pool,
  ) {
    try {
      const lessonId = await LessonModule.create(
        name,
        className,
        subjectId,
        materialId,
        teacherId,
        date,
        db,
      );
      return { lessonId, message: "Lesson created successfully" };
    } catch (error) {
      console.error("Service Error in createLesson:", error.message);
      throw error;
    }
  }

  static async updateLesson(
    lessonId,
    name,
    className,
    subjectId,
    materialId,
    teacherId,
    date,
    db = pool,
  ) {
    try {
      await LessonModule.update(
        lessonId,
        name,
        className,
        subjectId,
        materialId,
        teacherId,
        date,
        db,
      );
      return { message: "Lesson updated successfully" };
    } catch (error) {
      console.error("Service Error in updateLesson:", error.message);
      throw error;
    }
  }

  static async deleteLesson(lessonId, db = pool) {
    try {
      await LessonModule.delete(lessonId, db);
      return { message: `Lesson ${lessonId} deleted successfully` };
    } catch (error) {
      console.error("Service Error in deleteLesson:", error.message);
      throw error;
    }
  }
}

export default LessonService;


