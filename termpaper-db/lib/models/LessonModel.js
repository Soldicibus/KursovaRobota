import pool from "../db.js";

class LessonModule {
  static async findAll(db = pool) {
    const query = `SELECT * FROM lessons`;
    try {
      const lessons = await db.query(query);
      if (lessons.rows && lessons.rows.length > 0) {
        return lessons.rows;
      }
      return [];
    } catch (error) {
      console.error("Error in findAll: Could not retrieve all lessons.", error);
      throw new Error("Database error: Failed to fetch all lessons.");
    }
  }

  static async findById(id, db = pool) {
    const query = `SELECT * FROM lessons WHERE lesson_id=$1`;
    const values = [id];

    try {
      const lessons = await db.query(query, values);
      if (lessons.rows && lessons.rows.length > 0) {
        return lessons.rows[0];
      }
      return null;
    } catch (error) {
      console.error(
        `Error in findById: Could not retrieve lesson with ID ${id}.`,
        error,
      );
      throw new Error(`Database error: Failed to fetch lesson by ID ${id}.`);
    }
  }

  static async findByName(name, db = pool) {
    const query = `SELECT * FROM lessons WHERE lesson_name=$1`;
    const values = [name];
    try {
      const lessons = await db.query(query, values);
      if (lessons.rows && lessons.rows.length > 0) {
        return lessons.rows[0];
      }
      return null;
    } catch (error) {
      console.error(
        `Error in findByName: Could not retrieve lesson with name ${name}.`,
        error,
      );
      throw new Error(`Database error: Failed to fetch lesson by name ${name}.`);
    }
  }

  // Procedures

  static async create(
    p_name,
    p_class,
    p_subject,
    p_material,
    p_teacher,
    p_date,
    db = pool,
  ) {
    const query = `CALL proc_create_lesson($1::character varying, $2::character varying, $3::integer, $4::integer, $5::integer, $6::timestamp without time zone, NULL::integer)`;
    const formattedDate = p_date ? p_date.replace('T', ' ') : p_date;
    const values = [p_name, p_class, p_subject, p_material, p_teacher, formattedDate];
    if (process.env.NODE_ENV !== "production") console.log("Creating lesson with params:", {
      p_name,
      p_class,
      p_subject,
      p_material,
      p_teacher,
      formattedDate,
    });
    try {
      const newLesson = await db.query(query, values);
      if (newLesson.rows && newLesson.rows.length > 0) {
        return newLesson.rows[0].new_lesson_id;
      }
      return null;
    } catch (error) {
      console.error(
        `Error in create: Could not create new lesson '${p_name}'.`,
        error,
      );
      throw new Error(
        "Database error: Failed to execute lesson creation procedure.",
      );
    }
  }

  static async update(
    p_lesson_id,
    p_name,
    p_class,
    p_subject,
    p_material,
    p_teacher,
    p_date,
    db = pool,
  ) {
    const query = `CALL proc_update_lesson($1::integer, $2::character varying, $3::character varying, $4::integer, $5::integer, $6::integer, $7::timestamp without time zone)`;
    const formattedDate = p_date ? p_date.replace('T', ' ') : p_date;
    const values = [
      p_lesson_id,
      p_name,
      p_class,
      p_subject,
      p_material,
      p_teacher,
      formattedDate,
    ];
    console.log("Updating lesson with params:", {
      p_lesson_id,
      p_name,
      p_class,
      p_subject,
      p_material,
      p_teacher,
      formattedDate,
    });
    try {
      await db.query(query, values);
      return true;
    } catch (error) {
      console.error(
        `Error in update: Could not update lesson with ID ${p_lesson_id}.`,
        error,
      );
      throw new Error(
        `Database error: Failed to execute lesson update procedure for ID ${p_lesson_id}.`,
      );
    }
  }

  static async delete(p_id, db = pool) {
    const query = `CALL proc_delete_lesson($1::integer)`;
    const values = [p_id];
    try {
      await db.query(query, values);
      return true;
    } catch (error) {
      console.error(
        `Error in delete: Could not delete lesson with ID ${p_id}.`,
        error,
      );
      throw new Error(
        `Database error: Failed to execute lesson delete procedure for ID ${p_id}.`,
      );
    }
  }
}

export default LessonModule;
