import pool from "../db.js";

class SubjectsModel {
  static async findAll(db = pool) {
    const query = `SELECT * FROM subjects`;
    try {
      const result = await db.query(query);
      return result.rows;
    } catch (error) {
      console.error("Database Error in SubjectsModel.findAll:", error);
      throw new Error("Failed to retrieve subjects list.");
    }
  }

  static async create(name, program, db = pool) {
    const query = `
      INSERT INTO subjects (subject_name, subject_program)
      VALUES ($1, $2)
      RETURNING *`;
    const values = [name, program];

    try {
      const result = await db.query(query, values);
      return result.rows[0];
    } catch (error) {
      console.error("Database Error in SubjectsModel.create:", error);

      if (error.code === "23505") {
        throw new Error(`Subject with name '${name}' already exists.`);
      }

      throw new Error("Failed to create new subject due to database failure.");
    }
  }

  static async delete(id, db = pool) {
    const query = `DELETE FROM subjects WHERE subject_id = $1`;
    const values = [id];

    try {
      await db.query(query, values);
      return { message: `Subject ${id} deleted successfully.` };
    } catch (error) {
      console.error("Database Error in SubjectsModel.delete:", error);
      if (error.code === "23503") {
        throw new Error(
          `Cannot delete subject ${id} because it is referenced by active lessons.`,
        );
      }
      throw new Error("Failed to delete subject.");
    }
  }
}

export default SubjectsModel;
