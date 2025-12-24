import pool from "../db.js";

class StudentDataModule {
  static async findAll(db = pool) {
    const query = `SELECT * FROM studentdata`;
    try {
      const studentData = await db.query(query);
      if (studentData.rows && studentData.rows.length > 0) {
        return studentData.rows;
      }
      return [];
    } catch (error) {
      console.error(
        "Error in findAll: Could not retrieve all student data.",
        error,
      );
      throw new Error("Database error: Failed to fetch all student data.");
    }
  }

  static async findById(id, db = pool) {
    const query = `SELECT * FROM studentdata WHERE studentdata_id=$1`;
    const values = [id];

    try {
      const studentData = await db.query(query, values);
      if (studentData.rows && studentData.rows.length > 0) {
        return studentData.rows[0];
      }
      return null;
    } catch (error) {
      console.error(
        `Error in findById: Could not retrieve student data with ID ${id}.`,
        error,
      );
      throw new Error(
        `Database error: Failed to fetch student data by ID ${id}.`,
      );
    }
  }

  // Procedures

  static async create(
    p_journal_id,
    p_student_id,
    p_lesson,
    p_mark,
    p_status,
    p_note,
    db = pool,
  ) {
    const query = `CALL proc_create_studentdata($1::integer, $2::integer, $3::integer, $4::smallint, $5::journal_status_enum, $6::text, NULL)`;
    const values = [
      p_journal_id,
      p_student_id,
      p_lesson,
      p_mark,
      p_status,
      p_note,
    ];

    try {
      const newStudentData = await db.query(query, values);
      if (newStudentData.rows && newStudentData.rows.length > 0) {
        return newStudentData.rows[0].new_data_id;
      }
      return null;
    } catch (error) {
      console.error(
        `Error in create: Could not create new student data for student ${p_student_id} in lesson ${p_lesson}.`,
        error,
      );
      throw new Error(
        "Database error: Failed to execute student data creation procedure.",
      );
    }
  }

  static async update(
    p_id,
    p_journal_id,
    p_student_id,
    p_lesson,
    p_mark,
    p_status,
    p_note,
    db = pool,
  ) {
    const query = `CALL proc_update_studentdata($1::integer, $2::integer, $3::integer, $4::integer, $5::smallint, $6::journal_status_enum, $7::text)`;
    const values = [
      p_id,
      p_journal_id,
      p_student_id,
      p_lesson,
      p_mark,
      p_status,
      p_note,
    ];
    try {
      await db.query(query, values);
      return true;
    } catch (error) {
      console.error(
        `Error in update: Could not update student data with ID ${p_id}.`,
        error,
      );
      throw new Error(
        `Database error: Failed to execute student data update procedure for ID ${p_id}.`,
      );
    }
  }

  static async delete(p_id, db = pool) {
    const query = `CALL proc_delete_studentdata($1::integer)`;
    const values = [p_id];
    try {
      await db.query(query, values);
      return true;
    } catch (error) {
      console.error(
        `Error in delete: Could not delete student data with ID ${p_id}.`,
        error,
      );
      throw new Error(
        `Database error: Failed to execute student data delete procedure for ID ${p_id}.`,
      );
    }
  }

  static async findMarks7d(studentId, db = pool) {
    const query = `SELECT * FROM get_student_grade_entries($1::integer)`;
    const values = [studentId];
    try {
      const result = await db.query(query, values);
      return result.rows;
    } catch (error) {
      console.error(
        `Error in findMarks7d: Could not retrieve marks for student ${studentId}.`,
        error,
      );
      // If DB function is not available or errors out, return empty set so API can respond 200
      return [];
    }
  }

  static async findMarks(studentId, from, to, db = pool) {
    const query = `SELECT * FROM get_student_grade_entries($1::integer, $2::date, $3::date)`;
    const values = [studentId, from, to];
    try {
      const result = await db.query(query, values);
      return result.rows;
    } catch (error) {
      console.error(
        `Error in findMarks: Could not retrieve marks for student ${studentId} from ${from} to ${to}.`,
        error,
      );
      throw new Error(
        `Database error: Failed to fetch marks for student ${studentId} in the specified date range.`,
      );
    }
  }
}

export default StudentDataModule;
