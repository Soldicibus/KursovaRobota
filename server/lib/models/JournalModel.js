import pool from "../db.js";

class JournalModel {
  static async findAll(db = pool) {
    const query = `SELECT * FROM vws_journals`;
    try {
      const result = await db.query(query);
      return result.rows || null;
    } catch (error) {
      console.error("DB Error in JournalModel.findAll:", error);
      throw new Error("Failed to retrieve journal data.");
    }
  }
  static async findById(id, db = pool) {
    const query = `SELECT * FROM vws_journals WHERE journal_id = $1`;
    const values = [id];
    try {
      const result = await db.query(query, values);
      return result.rows[0] || null;
    } catch (error) {
      console.error("DB Error in JournalModel.findById:", error);
      throw new Error("Failed to retrieve journal data.");
    }
  }

  static async create(teacherId, name, db = pool) {
    const query = `CALL proc_create_journal($1::integer, $2::character varying)`;
    const values = [teacherId, name];

    try {
      await db.query(query, values);
      const selectQuery = `SELECT * FROM vws_journals WHERE journal_teacher = $1 AND journal_name = $2 ORDER BY journal_id DESC LIMIT 1`;
      const result = await db.query(selectQuery, [teacherId, name]);
      return result.rows[0];
    } catch (error) {
      console.error("DB Error in JournalModel.create:", error);
      if (error.code === "23503") {
        // Foreign Key Violation
        throw new Error(`Invalid Teacher ID provided.`);
      }
      throw new Error("Failed to create new journal.");
    }
  }

  static async update(id, teacherId, name, db = pool) {
    const query = `CALL proc_update_journal($1::integer, $2::integer, $3::character varying)`;
    const values = [id, teacherId, name];

    try {
      await db.query(query, values);
      const selectQuery = `SELECT * FROM vws_journals WHERE journal_id = $1`;
      const result = await db.query(selectQuery, [id]);
      return result.rows[0];
    } catch (error) {
      console.error("DB Error in JournalModel.update:", error);
      if (error.code === "23503") {
        throw new Error(`Invalid Teacher ID provided for update.`);
      }
      throw new Error("Failed to update journal information.");
    }
  }

  static async delete(id, db = pool) {
    const query = `CALL proc_delete_journal($1::integer)`;
    const values = [id];

    try {
      await db.query(query, values);
      return { message: `Journal ${id} deleted successfully.` };
    } catch (error) {
      console.error("DB Error in JournalModel.delete:", error);
      if (error.code === "23503") {
        throw new Error(
          `Cannot delete journal ${id} because it is linked to a class.`,
        );
      }
      throw new Error("Failed to delete journal.");
    }
  }

  static async findByStudentId(studentId, db = pool) {
    const query = `SELECT subject, mark, lesson_date FROM get_journal_by_student($1::integer)`;
    const values = [studentId];
    try {
      const result = await db.query(query, values);
      return result.rows || [];
    } catch (error) {
      // Fallback: if the DB does not have that function, try a common table name
      console.warn(
        "[JournalModel] get_journal_by_student failed, attempting fallback query",
        error.message,
      );
      try {
        const fallbackQuery = `SELECT subject, mark, lesson_date FROM journal_entries WHERE student_id = $1 ORDER BY lesson_date DESC`;
        const fallbackRes = await db.query(fallbackQuery, values);
        return fallbackRes.rows || [];
      } catch (err) {
        console.error("DB Error in JournalModel.findByStudentId (fallback failed):", err);
        // Do not throw - return empty set so controller can return 200 with empty entries
        return [];
      }
    }
  }
}

export default JournalModel;
