import TeacherModel from "../../lib/models/TeacherModel.js";
import pool from "../../lib/db.js";

class TeacherService {
  static async getAllTeachers(db = pool) {
    try {
      const teachers = await TeacherModel.findAll(db);
      return { teachers };
    } catch (error) {
      console.error("Service Error in getAllTeachers:", error.message);
      throw error;
    }
  }

  static async getTeacherById(teacherId, db = pool) {
    try {
      const teacher = await TeacherModel.findById(teacherId, db);
      if (!teacher) {
        throw new Error(`Teacher with ID ${teacherId} not found`);
      }
      return { teacher };
    } catch (error) {
      console.error("Service Error in getTeacherById:", error.message);
      throw error;
    }
  }

  static async getTeachersWithClasses(teacherId, db = pool) {
    try {
      const teachers = await TeacherModel.withClasses(teacherId, db);
      return { teachers };
    } catch (error) {
      console.error("Service Error in getTeachersWithClasses:", error.message);
      throw error;
    }
  }

  static async getTeachersWithClassesByName(className, db = pool) {
    try {
      const teachers = await TeacherModel.withClassesByName(className, db);
      return { teachers };
    } catch (error) {
      console.error("Service Error in getTeachersWithClassesByName:", error.message);
      throw error;
    }
  }

  static async getTeacherSalary(teacherId, fromDate, toDate, db = pool) {
    try {
      const salary = await TeacherModel.recieveSalary(
        teacherId,
        fromDate,
        toDate,
        db,
      );
      return { salary };
    } catch (error) {
      console.error("Service Error in getTeacherSalary:", error.message);
      throw error;
    }
  }

  static async createTeacher(name, surname, patronym, phone, db = pool) {
    if (!name || !surname || !phone) {
      throw new Error("name, surname, and phone are required");
    }
    try {
      const teacherId = await TeacherModel.create(
        name,
        surname,
        patronym || null,
        phone,
        db,
      );
      return { teacherId, message: "Teacher created successfully" };
    } catch (error) {
      console.error("Service Error in createTeacher:", error.message);
      throw error;
    }
  }

  static async updateTeacher(id, name, surname, patronym, phone, db = pool) {
    if (!id || !name || !surname || !phone) {
      throw new Error("id, name, surname, and phone are required");
    }
    try {
      await TeacherModel.update(id, name, surname, patronym || null, phone, db);
      return { message: "Teacher updated successfully" };
    } catch (error) {
      console.error("Service Error in updateTeacher:", error.message);
      throw error;
    }
  }

  static async deleteTeacher(teacherId, db = pool) {
    try {
      await TeacherModel.delete(teacherId, db);
      return { message: `Teacher ${teacherId} deleted successfully` };
    } catch (error) {
      console.error("Service Error in deleteTeacher:", error.message);
      throw error;
    }
  }
}

export default TeacherService;
