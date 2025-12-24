import pool from "../db.js";

class DayModule {
  static async findAll(db = pool) {
    const query = `SELECT * FROM days`;
    try {
      const days = await db.query(query);
      if (days.rows && days.rows.length > 0) {
        return days.rows;
      }
      return [];
    } catch (error) {
      console.error("Error in findAll: Could not retrieve all days.", error);
      throw new Error("Database error: Failed to fetch all days.");
    }
  }

  static async findById(id, db = pool) {
    const query = `SELECT * FROM days WHERE day_id=$1`;
    const values = [id];

    try {
      const days = await db.query(query, values);
      if (days.rows && days.rows.length > 0) {
        return days.rows[0];
      }
      return null;
    } catch (error) {
      console.error(
        `Error in findById: Could not retrieve day with ID ${id}.`,
        error,
      );
      throw new Error(`Database error: Failed to fetch day by ID ${id}.`);
    }
  }

  // Procedures

  static async create(p_subjectId, p_timetableId, p_day_time, p_day_weekday, db = pool) {
    const query = `CALL proc_create_day($1::integer, $2::integer, $3::time without time zone, $4::character varying, NULL)`;
    const values = [p_subjectId, p_timetableId, p_day_time, p_day_weekday];

    try {
      const newDay = await db.query(query, values);
      if (newDay.rows && newDay.rows.length > 0) {
        return newDay.rows[0].new_day_id;
      }
      return null;
    } catch (error) {
      console.error(
        `Error in create: Could not create new day entry '${p_day_name}'.`,
        error,
      );
      if (error.code === '23503') {
        throw new Error(
          `Foreign key violation: Please ensure that the subjectId ${p_subjectId} and timetableId ${p_timetableId} exist.`,
        );
      }
      if (error.code === '23514') {
        throw new Error(
          `Check constraint violation: Please ensure that the dayTime and dayWeekday values are valid.`,
        );
      }
      throw new Error(
        "Database error: Failed to execute day creation procedure.",
      );
    }
  }

  static async update(p_id, p_subjectId, p_timetableId, p_time, p_weekday, db = pool) {
    const query = `CALL proc_update_day($1::integer, $2::integer, $3::integer, $4::time without time zone, $5::character varying)`;
    const values = [p_id, p_subjectId, p_timetableId, p_time, p_weekday];
    try {
      await db.query(query, values);
      return true;
    } catch (error) {
      console.error(
        `Error in update: Could not update day with ID ${p_id}.`,
        error,
      );
      if (error.code === '23503') {
        throw new Error(
          `Foreign key violation: Please ensure that the subjectId ${p_subjectId} and timetableId ${p_timetableId} exist.`,
        );
      }
      if (error.code === '23514') {
        throw new Error(
          `Check constraint violation: Please ensure that the dayTime and dayWeekday values are valid.`,
        );
      }
      throw new Error(
        `Database error: Failed to execute day update procedure for ID ${p_id}.`,
      );
    }
  }

  static async delete(p_id, db = pool) {
    const query = `CALL proc_delete_day($1::integer)`;
    const values = [p_id];
    try {
      await db.query(query, values);
      return true;
    } catch (error) {
      console.error(
        `Error in delete: Could not delete day with ID ${p_id}.`,
        error,
      );
      throw new Error(
        `Database error: Failed to execute day delete procedure for ID ${p_id}.`,
      );
    }
  }
}

export default DayModule;
