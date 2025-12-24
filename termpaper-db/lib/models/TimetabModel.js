import pool from "../db.js";

class TimetableModel {
  static async find(db = pool) {
    const query = `SELECT * FROM timetable`;
    try {
      const result = await db.query(query);
      return result.rows || null;
    } catch (error) {
      console.error("DB Error in TimetableModel.findAll:", error);
      throw new Error("Failed to retrieve timetable data.");
    }
  }
  static async findById(id, db = pool) {
    const query = `SELECT * FROM timetable WHERE timetable_id = $1`;
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
    const query = `
      INSERT INTO timetable (timetable_name, timetable_class)
      VALUES ($1, $2)
      RETURNING *`;
    const values = [name, class_name];

    try {
      const result = await db.query(query, values);
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
    const query = `
      UPDATE timetable SET 
      timetable_name = $2, 
      timetable_class = $3
      WHERE timetable_id = $1
      RETURNING *`;
    const values = [id, name, class_name];

    try {
      const result = await db.query(query, values);
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
    const query = `DELETE FROM timetable WHERE timetable_id = $1`;
    const values = [id];

    try {
      const result = await db.query(query, values);
      if (result.rowCount === 0) {
        return { message: `Timetable ${id} not found.` };
      }
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
