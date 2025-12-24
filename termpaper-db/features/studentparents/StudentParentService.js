import StudentParentModel from "../../lib/models/StudentParentModel.js";
import pool from "../../lib/db.js";

class StudentParentService {
  static async getParentsByStudentId(studentId, db = pool) {
    try {
      const parents = await StudentParentModel.findByStudentId(studentId, db);
      return { parents };
    } catch (error) {
      console.error(
        "Service Error in getParentsByStudentId:",
        error.message,
      );
      throw error;
    }
  }

  static async getChildren(parentId, db = pool) {
    try {
      const students = await StudentParentModel.findChildren(parentId, db);
      return { students };
    } catch (error) {
      console.error("Service Error in getChildren:", error.message);
      throw error;
    }
  }

  static async assignParentToStudent(studentId, parentId, db = pool) {
    try {
      const result = await StudentParentModel.assign(studentId, parentId, db);
      return {
        result,
        message: `Parent ${parentId} assigned to Student ${studentId}`,
      };
    } catch (error) {
      console.error("Service Error in assignParentToStudent:", error.message);
      throw error;
    }
  }

  static async unassignParentFromStudent(studentId, parentId, db = pool) {
    try {
      const result = await StudentParentModel.unassign(studentId, parentId, db);
      return result;
    } catch (error) {
      console.error(
        "Service Error in unassignParentFromStudent:",
        error.message,
      );
      throw error;
    }
  }
}

export default StudentParentService;


