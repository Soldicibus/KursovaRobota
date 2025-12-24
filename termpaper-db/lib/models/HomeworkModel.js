import pool from "../db.js";

class HomeworkModule {
  static async findAll(db = pool) {
    const query = `SELECT * FROM homework`;
    try {
      const homework = await db.query(query);
      if (homework.rows && homework.rows.length > 0) {
        return homework.rows;
      }
      return []; 
    } catch (error) {
      console.error("Error in findAll: Could not retrieve all homework.", error);
      throw new Error("Database error: Failed to fetch all homework.");
    }
  }

  static async findById(id, db = pool) {
    const query = `SELECT * FROM homework WHERE homework_id=$1`;
    const values = [id];

    try {
      const homework = await db.query(query, values);
      if (homework.rows && homework.rows.length > 0) {
        return homework.rows[0]; 
      }
      return null; 
    } catch (error) {
      console.error(`Error in findById: Could not retrieve homework with ID ${id}.`, error);
      throw new Error(`Database error: Failed to fetch homework by ID ${id}.`);
    }
  }

  // Views

  static async recieveByStudentOrClass(studentId, db = pool) {
    const query = `SELECT * FROM vw_homework_by_student_or_class WHERE student_id=$1`
    const values = [studentId];
    try {
      const homework = await db.query(query, values);
      if (homework.rows && homework.rows.length > 0) {
        return homework.rows;
      }
      return [];
    } catch (error) {
      console.error("Error in recieveByStudentOrClass: Could not retrieve homework from view.", error);
      throw new Error("Database error: Failed to fetch homework by student or class view.");
    }
  }

  static async reciefveForTomorrow(db = pool) {
    const query = `SELECT * FROM vw_homework_tomorrow`;
    try {
      const homework = await db.query(query);
      if (homework.rows && homework.rows.length > 0) {
        return homework.rows;
      }
      return [];
    } catch (error) {
      console.error("Error in reciefveForTomorrow: Could not retrieve homework for tomorrow's view.", error);
      throw new Error("Database error: Failed to fetch homework for tomorrow view.");
    }
  }

  // Functions

  static async findByCreateDate(class_c, date, db = pool) { //demo
    const query = `SELECT * FROM get_homework_by_createdate($1::character varying, $2::date)`;
    const values = [class_c, date];
    try {
      const homework = await db.query(query, values);
      if (homework.rows && homework.rows.length > 0) {
        return homework.rows;
      }
      return [];
    } catch (error) {
      console.error(`Error in findByCreateDate: Could not retrieve homework for class ${class_c} on ${date}.`, error);
      throw new Error("Database error: Failed to execute get_homework_by_createdate function.");
    }
  }

  static async findByDueDate(class_c, date, db = pool) { //demo
    const query = `SELECT * FROM get_homework_by_duedate($1::character varying, $2::date)`;
    const values = [class_c, date];
    try {
      const homework = await db.query(query, values);
      if (homework.rows && homework.rows.length > 0) {
        return homework.rows;
      }
      return [];
    } catch (error) {
      console.error(`Error in findByDueDate: Could not retrieve homework for class ${class_c} on ${date}.`, error);
      throw new Error("Database error: Failed to execute get_homework_by_due_date function.");
    }
  }

  // Procedures

  static async create(name, teacher, lesson, duedate, desc, class_c, db = pool) {
    if (process.env.NODE_ENV !== "production") console.log("Creating homework:", { name, teacher, lesson, duedate, desc, class_c });
    const query = `CALL proc_create_homework($1::character varying, $2::integer, $3::integer, $4::date, $5::text, $6::character varying, NULL::integer)`;
    const values = [name, teacher, lesson, duedate, desc, class_c];
    try {
      const newHomework = await db.query(query, values);
      if (newHomework.rows && newHomework.rows.length > 0) {
        return newHomework.rows[0].new_homework_id;
      }
      return null; 
    } catch (error) {
      console.error(`Error in create: Could not create new homework '${name}'.`, error);
      if (error.code === '23503') {
        throw new Error("Foreign key constraint violation: Please ensure that the teacher, lesson, and class exist.");
      }
      if (error.code === '23505') {
        throw new Error("Unique constraint violation: A homework with the same details already exists.");
      }
      if (error.code === '22001') {
        throw new Error("Data too long for column: Please ensure all text fields are within the allowed length.");
      }
      if (error.code === '23502') {
        throw new Error("Not null constraint violation: Please ensure all required fields are provided.");
      }
      throw new Error("Database error: Failed to execute homework creation procedure.");
    }
  }

  static async update(id, name, teacher, lesson, duedate, desc, class_c, db = pool) {
    const query = `CALL proc_update_homework($1::integer, $2::character varying, $3::integer, $4::integer, $5::date, $6::text, $7::character varying)`;
    const values = [id, name, teacher, lesson, duedate, desc, class_c];
    try {
      await db.query(query, values);
      return true; 
    } catch (error) {
      console.error(`Error in update: Could not update homework with ID ${id}.`, error);
      throw new Error(`Database error: Failed to execute homework update procedure for ID ${id}.`);
    }
  }

  static async delete(id, db = pool) {
    const query = `CALL proc_delete_homework($1::integer)`;
    const values = [id];
    try {
      await db.query(query, values);
      return true; 
    } catch (error) {
      console.error(`Error in delete: Could not delete homework with ID ${id}.`, error);
      throw new Error(`Database error: Failed to execute homework delete procedure for ID ${id}.`);
    }
  }
}

export default HomeworkModule;
