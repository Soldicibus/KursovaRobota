import pool from "../db.js";
class StudentModel {
  static async findAll(db = pool) {
    const query = `SELECT * FROM vws_students`;

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
  static async findAllM(db = pool) {
    const query = `SELECT * FROM vws_all_students;`;
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
    const query = `
      SELECT s.*, u.email 
      FROM vws_students s
      LEFT JOIN vws_users u ON s.student_user_id = u.user_id
      WHERE s.student_id=$1
    `;
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

  static async studentPerformanceMatrix(studentId, db = pool) {
    const query = `SELECT * FROM vw_student_perfomance_matrix WHERE student_id = $1`;
    const values = [studentId];
    try {
      const students = await db.query(query, values);
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
  // CALL proc_create_student('A','A','A','091-321-4356',NULL::int,'12-Д',NULL::int,NULL::text)
  static async create(name, surname, patronym, phone, class_c = null, db = pool) {
    const query = `CALL proc_create_student($1::character varying, $2::character varying, $3::character varying, $4::character varying, NULL::integer, $5::character varying, NULL::integer, NULL::text)`;
    const values = [name, surname, patronym, phone, class_c];
    try {
      const newStudent = await db.query(query, values);
      if (newStudent.rows && newStudent.rows.length > 0) {
        return {
          id: newStudent.rows[0].new_student_id,
          generated_password: newStudent.rows[0].generated_password
        };
      }
      return null;
    } catch (error) {
      console.error(
        `Database error creating the student ${name}\t ${surname}\t ${patronym}\t ${phone}\t ${class_c}\t:`,
        error,
      );
      if (error.code === "23514") {
        throw new Error(`Required student fields cannot be empty.`);
      }
      if (error.code === "22003") {
        throw new Error(`Class '${class_c}' does not exist.`);
      }
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
      if (error.code === "22003") {
        throw new Error(`Student with ID ${id} or Class '${class_c}' does not exist.`);
      }
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
      if (error.code === "22003") {
        throw new Error(`Student with ID ${id} does not exist.`);
      }
      throw new Error(
        "Could not delete the student data due to a database error.",
      );
    }
  }
  static async monthlyMarks(studentId, month, db = pool) {
    // month is expected to be a valid date string or date object
    // If month is not provided, NULL will be passed to the function which defaults to CURRENT_DATE
    const query = `SELECT * FROM get_student_monthly_grades($1::integer, $2::TIMESTAMP WITHOUT TIME ZONE)`;
    const values = [studentId, month || null];

    try {
      const marks = await db.query(query, values);
      return marks.rows;
    } catch (error) {
      console.error(
        `Database error finding monthly marks for student ${studentId}:`,
        error,
      );
      throw new Error(
        "Could not retrieve monthly marks data due to a database error.",
      );
    }
  }
}
export default StudentModel;
