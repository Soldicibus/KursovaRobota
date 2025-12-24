import pool from "../db.js";

class StudentParentModel {
  static async findByStudentId(studentId, db = pool) {
    const query = `SELECT * FROM studentparent WHERE student_id_ref = $1`;
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
      if (error.code === "23503") {
        throw new Error(`Invalid Student ID or Parent ID provided.`);
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
      throw new Error("Failed to unlink student and parent.");
    }
  }
}

export default StudentParentModel;
