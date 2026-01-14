import pool from "../db.js";

class TimetableModel {
  static async find(db = pool) {
    const query = `SELECT * FROM vws_timetables`;
    try {
      const result = await db.query(query);
      return result.rows || null;
    } catch (error) {
      console.error("DB Error in TimetableModel.findAll:", error);
      throw new Error("Failed to retrieve timetable data.");
    }
  }
  static async findById(id, db = pool) {
    const query = `SELECT * FROM vws_timetables WHERE timetable_id = $1`;
    const values = [id];
    try {
      const result = await db.query(query, values);
      return result.rows[0] || null;
    } catch (error) {
      console.error("DB Error in TimetableModel.findById:", error);
      throw new Error("Failed to retrieve timetable data.");
    }
  }

  static async create(name, class_name, db = pool) {
    const query = `CALL proc_create_timetable($1::character varying, $2::character varying)`;
    const values = [name, class_name];

    try {
      await db.query(query, values);
      const selectQuery = `SELECT * FROM vws_timetables WHERE timetable_name = $1`;
      const result = await db.query(selectQuery, [name]);
      return result.rows[0];
    } catch (error) {
      console.error("DB Error in TimetableModel.create:", error);
      if (error.code === "23503") {
        throw new Error(`Invalid Class Name provided.`);
      }
      throw new Error("Failed to create new timetable.");
    }
  }

  static async update(id, name, class_name, db = pool) {
    const query = `CALL proc_update_timetable($1::integer, $2::character varying, $3::character varying)`;
    const values = [id, name, class_name];

    try {
      await db.query(query, values);
      const selectQuery = `SELECT * FROM vws_timetables WHERE timetable_id = $1`;
      const result = await db.query(selectQuery, [id]);
      return result.rows[0];
    } catch (error) {
      console.error("DB Error in TimetableModel.update:", error);
      if (error.code === "23503") {
        throw new Error(`Invalid Class Name provided for update.`);
      }
      throw new Error("Failed to update timetable information.");
    }
  }

  static async delete(id, db = pool) {
    const query = `CALL proc_delete_timetable($1::integer)`;
    const values = [id];

    try {
      await db.query(query, values);
      return { message: `Timetable ${id} deleted successfully.` };
    } catch (error) {
      console.error("DB Error in TimetableModel.delete:", error);
      if (error.code === "23503") {
        throw new Error(
          `Cannot delete timetable ${id} because it is linked to other records.`,
        );
      }
      throw new Error("Failed to delete timetable.");
    }
  }

  static async findTimetablebyStudentId(studentId, db = pool) {
    const query = `
      SELECT * FROM get_timetable_id_by_student_id($1)
    `;
    const values = [studentId];
    try {
      const result = await db.query(query, values);
      return result.rows || [];
    } catch (error) {
      console.error("DB Error in TimetableModel.findTimetablebyStudentid:", error);
      throw new Error("Failed to retrieve timetable data.");
    }
  }

  static async weekById(timetableId, db = pool) {
    const query = `
      SELECT * FROM vw_view_timetable_week WHERE timetable_id = $1
    `;
    const values = [timetableId];
    try {
      const result = await db.query(query, values);
      return result.rows || [];
    } catch (error) {
      console.error("DB Error in TimetableModel.weekById:", error);
      throw new Error("Failed to retrieve weekly timetable data.");
    }
  }
}

export default TimetableModel;
