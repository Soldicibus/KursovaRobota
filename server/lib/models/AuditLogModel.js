import pool from "../db.js";

class AuditLogModel {
  static async findAll(db = pool) {
    const query = `SELECT * FROM vws_audits ORDER BY changed_at DESC`;

    try {
      const result = await db.query(query);
      return result.rows && result.rows.length > 0 ? result.rows : [];
    } catch (error) {
      console.error(`Database error finding audit logs`, error);
      throw new Error("Could not retrieve audit logs data due to a database error.");
    }
  }
}

export default AuditLogModel;
