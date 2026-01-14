import pool from "../db.js";
class TeacherModel {
  static async findAll(db = pool) {
    const query = `SELECT * from vws_teachers`;

    try {
      const teachers = await db.query(query);
      if (teachers.rows && teachers.rows.length > 0) {
        return teachers.rows;
      }
      return null;
    } catch (error) {
      console.error(`Database error finding teachers`, error);
      throw new Error(
        "Could not retrieve teachers data due to a database error.",
      );
    }
  }
  static async findById(id, db = pool) {
    const query = `SELECT * FROM vws_teachers WHERE teacher_id = $1`;
    const values = [id];

    try {
      const teacher = await db.query(query, values);
      if (teacher.rows && teacher.rows.length > 0) {
        return teacher.rows[0];
      }
      return null;
    } catch (error) {
      console.error(`Database error finding teacher`, error);
      throw new Error(
        "Could not retrieve teacher data due to a database error.",
      );
    }
  }

  // Views

  static async withClasses(id, db = pool) {
    const query = `SELECT * from vw_teacher_class_students WHERE class_mainTeacher = ($1::integer)`;
    const values = [id];
    try {
      const teachers = await db.query(query, values);
      if (teachers.rows && teachers.rows.length > 0) {
        return teachers.rows;
      }
      return null;
    } catch (error) {
      console.error(`Database error finding teachers`, error);
      throw new Error(
        "Could not retrieve teachers data due to a database error.",
      );
    }
  }
  
  static async withClassesByName(name, db = pool) {
    const query = `SELECT * from vw_teacher_class_students WHERE class_name = ($1::character varying)`;
    const values = [name];
    try {
      const teachers = await db.query(query, values);
      if (teachers.rows && teachers.rows.length > 0) {
        return teachers.rows;
      }
      return null;
    } catch (error) {
      console.error(`Database error finding info class`, error);
      throw new Error(
        "Could not retrieve teachers data due to a database error.",
      );
    }
  }

  // Functions

  static async recieveSalary(teacherId, fromDate, toDate, db = pool) {
    const query = `SELECT * FROM get_teacher_salary($1::integer, $2::date, $3::date)`;
    const values = [teacherId, fromDate, toDate];

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

  // Procedures

  static async create(name, surname, patronym, phone, db = pool) {
    const query = `CALL proc_create_teacher($1::character varying, $2::character varying, $3::character varying, $4::character varying, NULL::integer, NULL::integer, NULL::text)`;
    const values = [name, surname, patronym, phone];

    try {
      const newTeacher = await db.query(query, values);
      if (newTeacher.rows && newTeacher.rows.length > 0) {
        return newTeacher.rows[0].new_teacher_id;
      }
      return null;
    } catch (error) {
      console.error(`Database error creating teacher: name=${name}, surname=${surname}, patronym=${patronym}, phone=${phone}`, error);
      if (error.code === "23514") {
        throw new Error(`Required teacher fields cannot be empty.`);
      }
      throw new Error(
        "Could not creating the teacher data due to a database error.",
      );
    }
  }

  static async update(id, name, surname, patronym, phone, db = pool) {
    const query = `CALL proc_update_teacher($1::integer, $2::character varying, $3::character varying, $4::character varying, $5::character varying, NULL::integer)`;
    const values = [id, name, surname, patronym, phone];

    try {
      await db.query(query, values);
    } catch (error) {
      console.error(
        `Database error updating the teacher\t ${id}\t ${name}\t ${surname}\t ${patronym}\t ${phone}\t:`,
        error,
      );
      if (error.code === "22003") {
        throw new Error(`Teacher with ID ${id} does not exist.`);
      }
      throw new Error(
        "Could not update the teacher data due to a database error.",
      );
    }
  }

  static async delete(id, db = pool) {
    const query = `CALL proc_delete_teacher($1::integer)`;
    const values = [id];

    try {
      await db.query(query, values);
    } catch (error) {
      console.error(`Database error deleting the teacher ${id}\t:`, error);
      throw new Error(
        "Could not delete the teacher data due to a database error.",
      );
    }
  }
}
export default TeacherModel;
