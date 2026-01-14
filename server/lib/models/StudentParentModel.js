import pool from "../db.js";

class StudentParentModel {
  static async findByStudentId(studentId, db = pool) {
    const query = `
      SELECT sp.*, p.* 
      FROM vws_student_parents sp
      JOIN vws_parents p ON sp.parent_id_ref = p.parent_id
      WHERE sp.student_id_ref = $1
    `;
    const values = [studentId];
    try {
      const result = await db.query(query, values);
      return result.rows;
    } catch (error) {
      console.error(
        "Database Error in StudentParentModel.findByStudentId:",
        error,
      );
      throw new Error("Failed to retrieve parent links for student.");
    }
  }

  static async findChildren(parentId, db = pool) {
    const query = `SELECT * FROM get_children_by_parent($1::integer)`;
    const values = [parentId];
    try {
      const result = await db.query(query, values);
      return result.rows;
    } catch (error) {
      console.error(
        "Database Error in StudentParentModel.findChildren:",
        error,
      );
      throw new Error("Failed to retrieve children for parent.");
    }
  }

  static async assign(studentId, parentId, db = pool) {
    const query = `CALL proc_assign_student_parent($1::integer, $2::integer)`;
    const values = [studentId, parentId];

    try {
      const result = await db.query(query, values);
      return result.rows[0];
    } catch (error) {
      console.error("Database Error in StudentParentModel.create:", error);
      if (error.code === "22003") {
        throw new Error(`Student with ID ${studentId} or Parent with ID ${parentId} does not exist.`);
      }
      if (error.code === "23505") {
        throw new Error(`Student with ID ${studentId} is already assigned to Parent with ID ${parentId}.`);
      }
      throw new Error("Failed to link student and parent.");
    }
  }

  static async unassign(studentId, parentId, db = pool) {
    const query = `CALL proc_unassign_student_parent($1::integer, $2::integer)`;
    const values = [studentId, parentId];

    try {
      await db.query(query, values);
      return {
        message: `Link between Student ${studentId} and Parent ${parentId} deleted.`,
      };
    } catch (error) {
      console.error("Database Error in StudentParentModel.delete:", error);
      if (error.code === "22003") {
        throw new Error(`Assignment between Student ${studentId} and Parent ${parentId} does not exist.`);
      }
      throw new Error("Failed to unlink student and parent.");
    }
  }
}

export default StudentParentModel;
