import HomeworkModule from "../../lib/models/HomeworkModel.js";
import pool from "../../lib/db.js";

class HomeworkService {
  static async getAllHomework(db = pool) {
    try {
      const homework = await HomeworkModule.findAll(db);
      return { homework };
    } catch (error) {
      console.error("Service Error in getAllHomework:", error.message);
      throw error;
    }
  }

  static async getHomeworkById(homeworkId, db = pool) {
    try {
      const homework = await HomeworkModule.findById(homeworkId, db);
      if (!homework) {
        throw new Error(`Homework with ID ${homeworkId} not found`);
      }
      return { homework };
    } catch (error) {
      console.error("Service Error in getHomeworkById:", error.message);
      throw error;
    }
  }

  static async getHomeworkByStudentOrClass(studentId, db = pool) {
    try {
      const homework = await HomeworkModule.recieveByStudentOrClass(studentId, db);
      return { homework };
    } catch (error) {
      console.error(
        "Service Error in getHomeworkByStudentOrClass:",
        error.message,
      );
      throw error;
    }
  }

  static async getHomeworkForTomorrow(db = pool) {
    try {
      const homework = await HomeworkModule.reciefveForTomorrow(db);
      return { homework };
    } catch (error) {
      console.error(
        "Service Error in getHomeworkForTomorrow:",
        error.message,
      );
      throw error;
    }
  }

  static async createHomework(
    name,
    teacherId,
    lessonId,
    dueDate,
    description,
    className,
    db = pool,
  ) {
    if (!teacherId || !lessonId || !dueDate || !description || !className) {
      throw new Error("teacherId, lessonId, dueDate, description, and className are required");
    }
    try {
      const homework = await HomeworkModule.create(
        name || null,
        teacherId,
        lessonId,
        dueDate,
        description,
        className,
        db,
      );
      return { homework, message: "Homework created successfully" };
    } catch (error) {
      console.error("Service Error in createHomework:", error.message);
      throw error;
    }
  }

  static async updateHomework(
    id,
    name,
    teacherId,
    lessonId,
    dueDate,
    description,
    className,
    db = pool,
  ) {
    if (!id || !teacherId || !lessonId || !dueDate || !description || !className) {
      throw new Error("id, teacherId, lessonId, dueDate, description, and className are required");
    }
    try {
      const homework = await HomeworkModule.update(
        id,
        name || null,
        teacherId,
        lessonId,
        dueDate,
        description,
        className,
        db,
      );
      return { homework, message: "Homework updated successfully" };
    } catch (error) {
      console.error("Service Error in updateHomework:", error.message);
      throw error;
    }
  }

  static async deleteHomework(id, db = pool) {
    try {
      const result = await HomeworkModule.delete(id, db);
      return result;
    } catch (error) {
      console.error("Service Error in deleteHomework:", error.message);
      throw error;
    }
  }
}

export default HomeworkService;

