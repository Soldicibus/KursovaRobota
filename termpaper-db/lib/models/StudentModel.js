import pool from "../db.js";
class StudentModel {
  static async findAll(db = pool) {
    const query = `SELECT * FROM students`;

    try {
      const students = await db.query(query);

      if (students.rows && students.rows.length > 0) {
        return students.rows;
      }
      return null;
    } catch (error) {
      console.error(`Database error finding students`, error);
      throw new Error(
        "Could not retrieve students data due to a database error.",
      );
    }
  }
  static async findById(id, db = pool) {
    const query = `SELECT * FROM students WHERE student_id=$1`;
    const values = [id];

    try {
      const student = await db.query(query, values);
      if (student.rows && student.rows.length > 0) {
        return student.rows[0];
      }
      return null;
    } catch (error) {
      console.error(`Database error finding student ${id}:`, error);
      throw new Error(
        "Could not retrieve student data due to a database error.",
      );
    }
  }

  //Views

  static async AVGAbove7(db = pool) {
    const query = `SELECT * FROM vw_students_avg_above_7`;
    try {
      const students = await db.query(query);
      if (students.rows && students.rows.length > 0) {
        return students.rows;
      }
      return null;
    } catch (error) {
      console.error(`Database error finding studens:`, error);
      throw new Error(
        "Could not retrieve students data due to a database error.",
      );
    }
  }

  static async getByClass(db = pool) {
    const query = `SELECT * FROM vw_students_by_class`;
    try {
      const students = await db.query(query);
      if (students.rows && students.rows.length > 0) {
        return students.rows;
      }
      return null;
    } catch (error) {
      console.error(`Database error finding students:`, error);
      throw new Error(
        "Could not retrieve students data due to a database error.",
      );
    }
  }

  static async recieveRanking(db = pool) {
    const query = `SELECT * FROM vw_student_ranking`;
    try {
      const students = await db.query(query);
      if (students.rows && students.rows.length > 0) {
        return students.rows;
      }
      return null;
    } catch (error) {
      console.error(`Database error finding students:`, error);
      throw new Error(
        "Could not retrieve students data due to a database error.",
      );
    }
  }

  // Functions

  static async findByParentId(parentId) {
    const query = `SELECT * FROM get_children_by_parent($1::integer)`;
    const values = [parentId];

    try {
      const students = await pool.query(query, values);
      if (students.rows && students.rows.length > 0) {
        return students.rows;
      }
      return null;
    } catch (error) {
      console.error(`Database error finding students:`, error);
      throw new Error(
        "Could not retrieve students data due to a database error.",
      );
    }
  }
  static async recieveGradesAndAbsences(studentId, startDate, endDate, db = pool) {
    const query = `SELECT * FROM student_attendance_report($1::integer, $2::date, $3::date)`;
    const values = [studentId, startDate, endDate];

    try {
      const result = await db.query(query, values);
      if (result.rows && result.rows.length > 0) {
        return result.rows;
      }
    } catch (error) {
      console.error(`Database error finding data:`, error);
      throw new Error("Could not retrieve data due to a database error.");
    }
  }
  static async recieveMarks(studentId, startDate, endDate, db = pool) {
    const query = `SELECT * FROM get_student_marks($1::integer, $2::date, $3::date)`;
    const values = [studentId, startDate, endDate];

    try {
      const result = await db.query(query, values);
      if (result.rows && result.rows.length > 0) {
        return result.rows;
      }
      return null;
    } catch (error) {
      console.error(`Database error finding data:`, error);
      throw new Error("Could not retrieve data due to a database error.");
    }
  }
  static async recieveAttendanceReport(studentId, db = pool) {
    const query = `SELECT * FROM student_attendance_report($1::integer)`;
    const values = [studentId];

    try {
      const result = await db.query(query, values);
      if (result.rows && result.rows.length > 0) {
        return result.rows;
      }
      return null;
    } catch (error) {
      console.error(`Database error finding data:`, error);
      throw new Error("Could not retrieve data due to a database error.");
    }
  }
  static async recieveDayPlan(studentId, startDate, endDate) {
    const query = `SELECT * FROM student_day_plan($1::integer, $2::date, $3::date)`;
    const values = [studentId, startDate, endDate];

    try {
      const result = await pool.query(query, values);
      if (result.rows && result.rows.length > 0) return result.rows;
    } catch (err) {
      // If function not found (code 42883) or other DB errors, continue to next attempt
      console.warn(
        "[StudentModel] recieveDayPlan query failed, trying next fallback:",
        err.message,
      );
    }
    try {
      const fallbackQuery = `SELECT * FROM student_day_plan($1::integer)`;
      const result = await pool.query(fallbackQuery, [studentId]);
      if (result.rows && result.rows.length > 0) return result.rows;
    } catch (err) {
      // If function not found (code 42883) or other DB errors, continue to next attempt
      console.warn(
        "[StudentModel] recieveDayPlan query failed, trying next fallback:",
        err.message,
      );
    }
  }


  // Procedures

  static async create(name, surname, patronym, phone, class_c = null, db = pool) {
    const query = `CALL proc_create_student($1::character varying, $2::character varying, $3::character varying, $4::character varying, NULL::integer, $5::character varying, NULL::integer, NULL::text)`;
    const values = [name, surname, patronym, phone, class_c];
    try {
      const newStudent = await db.query(query, values);
      if (newStudent.rows && newStudent.rows.length > 0) {
        return newStudent.rows[0].new_student_id;
      }
      return null;
    } catch (error) {
      console.error(
        `Database error creating the student ${name}\t ${surname}\t ${patronym}\t ${phone}\t ${class_c}\t:`,
        error,
      );
      throw new Error(
        "Could not creating the student data due to a database error.",
      );
    }
  }
  static async update(
    id,
    name,
    surname,
    patronym,
    phone,
    class_c,
    db = pool,
  ) {
    const query = `CALL proc_update_student($1::integer, $2::character varying, $3::character varying, $4::character varying, $5::character varying, NULL::integer, $6::character varying)`;
    const values = [id, name, surname, patronym, phone, class_c];
    try {
      await db.query(query, values);
    } catch (error) {
      console.error(
        `Database error updating the student ${id}\t ${name}\t ${surname}\t ${patronym}\t ${phone}\t ${class_c}\t:`,
        error,
      );
      throw new Error(
        "Could not update the student data due to a database error.",
      );
    }
  }
  static async delete(id, db = pool) {
    const query = `CALL proc_delete_student($1::integer)`;
    const values = [id];
    try {
      await db.query(query, values);
    } catch (error) {
      console.error(`Database error deleting the student ${id}\t:`, error);
      throw new Error(
        "Could not delete the student data due to a database error.",
      );
    }
  }

  // NOTE: student contact lookup by arbitrary email/phone removed. It caused frequent
  // runtime DB errors in environments with heterogeneous schemas (missing columns)
  // and has been removed to keep behavior consistent and error-free. Use explicit
  // student ID lookups via `findById` or proper endpoints that map users to students.
}
export default StudentModel;
