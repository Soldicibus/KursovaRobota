import pool from "../db.js";

class RolesModel {
  static async findAll(db = pool) {
    const query = `SELECT * FROM vws_roles`;
    try {
      const result = await db.query(query);
      return result.rows || null;
    } catch (error) {
      console.error("DB Error in RolesModel.findAll:", error);
      throw new Error("Failed to retrieve role data.");
    }
  }
  static async findById(id, db = pool) {
    const query = `SELECT * FROM vws_roles WHERE role_id = $1`;
    const values = [id];
    try {
      const result = await db.query(query, values);
      return result.rows[0] || null;
    } catch (error) {
      console.error("DB Error in RolesModel.findById:", error);
      throw new Error("Failed to retrieve role data.");
    }
  }

  static async create(name, desc = null, db = pool) {
    const query = `CALL proc_create_role($1::character varying, $2::text)`;
    const values = [name, desc];

    try {
      await db.query(query, values);
      const selectQuery = `SELECT * FROM vws_roles WHERE role_name = $1`;
      const result = await db.query(selectQuery, [name]);
      return result.rows[0];
    } catch (error) {
      console.error("DB Error in RolesModel.create:", error);
      if (error.code === "23505") {
        throw new Error(`Role name '${name}' already exists.`);
      }
      throw new Error("Failed to create new role.");
    }
  }

  static async update(id, name, desc = null, db = pool) {
    const query = `CALL proc_update_role($1::integer, $2::character varying, $3::text)`;
    const values = [id, name, desc];

    try {
      await db.query(query, values);
      const selectQuery = `SELECT * FROM vws_roles WHERE role_id = $1`;
      const result = await db.query(selectQuery, [id]);
      return result.rows[0];
    } catch (error) {
      console.error("DB Error in RolesModel.update:", error);
      if (error.code === "23505") {
        throw new Error(`Role name '${name}' already exists.`);
      }
      throw new Error("Failed to update role name.");
    }
  }

  static async delete(id, db = pool) {
    const query = `CALL proc_delete_role($1::integer)`;
    const values = [id];

    try {
      await db.query(query, values);
      return { message: `Role ${id} deleted successfully.` };
    } catch (error) {
      console.error("DB Error in RolesModel.delete:", error);
      if (error.code === "23503") {
        throw new Error(
          `Cannot delete role ${id} because it is assigned to users.`,
        );
      }
      throw new Error("Failed to delete role.");
    }
  }
}

export default RolesModel;
