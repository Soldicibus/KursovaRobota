import StudentDataModule from "../../lib/models/StudentDataModel.js";
import pool from "../../lib/db.js";

class StudentDataService {
  static async getAllStudentData(db = pool) {
    try {
      const studentData = await StudentDataModule.findAll(db);
      return { studentData };
    } catch (error) {
      console.error("Service Error in getAllStudentData:", error.message);
      throw error;
    }
  }

  static async getStudentDataById(studentDataId, db = pool) {
    try {
      const studentData = await StudentDataModule.findById(studentDataId, db);
      if (!studentData) {
        throw new Error(`Student Data with ID ${studentDataId} not found`);
      }
      return { studentData };
    } catch (error) {
      console.error("Service Error in getStudentDataById:", error.message);
      throw error;
    }
  }

  static async createStudentData(
    journalId,
    studentId,
    lesson,
    mark,
    status,
    note,
    db = pool,
  ) {
    try {
      const studentDataId = await StudentDataModule.create(
        journalId,
        studentId,
        lesson,
        mark,
        status,
        note,
        db,
      );
      return { studentDataId, message: "Student data created successfully" };
    } catch (error) {
      console.error("Service Error in createStudentData:", error.message);
      throw error;
    }
  }

  static async updateStudentData(
    studentDataId,
    journalId,
    studentId,
    lesson,
    mark,
    status,
    note,
    db = pool,
  ) {
    try {
      await StudentDataModule.update(
        studentDataId,
        journalId,
        studentId,
        lesson,
        mark,
        status,
        note,
        db,
      );
      return { message: "Student data updated successfully" };
    } catch (error) {
      console.error("Service Error in updateStudentData:", error.message);
      throw error;
    }
  }

  static async deleteStudentData(studentDataId, db = pool) {
    try {
      await StudentDataModule.delete(studentDataId, db);
      return { message: `Student data ${studentDataId} deleted successfully` };
    } catch (error) {
      console.error("Service Error in deleteStudentData:", error.message);
      throw error;
    }
  }

  static async getStudentDataMarks7d(studentId, db = pool) {
    try {
      const marks = await StudentDataModule.findMarks7d(studentId, db);
      return { marks };
    } catch (error) {
      console.error("Service Error in getStudentDataMarks7d:", error.message);
      throw error;
    }
  }
}

export default StudentDataService;


