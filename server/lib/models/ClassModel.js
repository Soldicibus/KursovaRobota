import pool from "../db.js";

class ClassModel {
  static async findAll(db = pool) {
    const query = `SELECT * FROM vws_classes`;
    try {
      const result = await db.query(query);
      return result.rows || [];
    } catch (error) {
      console.error("DB Error in ClassModel.findAll:", error);
      throw new Error("Failed to retrieve class data.");
    }
  }
  static async findByName(className, db = pool) {
    const query = `SELECT * FROM vws_classes WHERE class_name = $1`;
    const values = [className];
    try {
      const result = await db.query(query, values);
      return result.rows[0] || null;
    } catch (error) {
      console.error("DB Error in ClassModel.findByName:", error);
      throw new Error("Failed to retrieve class data.");
    }
  }

  static async findRatingReport(db = pool) {
    const query = `SELECT * FROM vw_class_ranking`;
    try {
      const result = await db.query(query);
      return result.rows || [];
    } catch (error) {
      console.error("DB Error in ClassModel.findRatingReport:", error);
      throw new Error("Failed to retrieve class rating report.");
    }
  }

  static async findAbsentReport(className, amount, db = pool) {
    const query = `SELECT * FROM absents_more_than_x($1::character varying, $2::integer)`;
    const values = [className, amount];
    try {
      const result = await db.query(query, values);
      return result.rows || [];
    } catch (error) {
      console.error("DB Error in ClassModel.findAbsentReport:", error);
      throw new Error("Failed to retrieve class absent report.");
    }
  }

  static async create(name, journalId, mainTeacherId, db = pool) {
    const query = `CALL proc_create_class($1::character varying, $2::integer, $3::integer)`;
    const values = [name, journalId, mainTeacherId];

    try {
      await db.query(query, values);
      const selectQuery = `SELECT * FROM class WHERE class_name = $1`;
      const result = await db.query(selectQuery, [name]);
      return result.rows[0];
    } catch (error) {
      console.error("DB Error in ClassModel.create:", error);
      if (error.code === "23505") {
        throw new Error(`Class with Name ${name} already exists.`);
      }
      if (error.code === "23503") {
        throw new Error(`Invalid Journal ID or Teacher ID provided.`);
      }
      throw new Error("Failed to create new class.");
    }
  }

  static async update(name, journalId, mainTeacherId, db = pool) {
    const query = `CALL proc_update_class($1::character varying, $2::integer, $3::integer)`;
    const values = [name, journalId, mainTeacherId];

    try {
      await db.query(query, values);
      const selectQuery = `SELECT * FROM class WHERE class_name = $1`;
      const result = await db.query(selectQuery, [name]);
      return result.rows[0];
    } catch (error) {
      console.error("DB Error in ClassModel.update:", error);
      if (error.code === "23503") {
        throw new Error(`Invalid Teacher ID provided for update.`);
      }
      throw new Error("Failed to update class information.");
    }
  }

  static async delete(name, db = pool) {
    const query = `CALL proc_delete_class($1::character varying)`;
    const values = [name];

    try {
      await db.query(query, values);
      return { message: `Class with name ${name} deleted successfully.` };
    } catch (error) {
      console.error("DB Error in ClassModel.delete:", error);
      if (error.code === "23503") {
        throw new Error(
          `Cannot delete class because it has associated students or timetables.`,
        );
      }
      throw new Error("Failed to delete class.");
    }
  }
}

export default ClassModel;
