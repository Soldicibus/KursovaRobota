import pool from "../db.js";

class MaterialModule {
  static async findAll(db = pool) {
    const query = `SELECT * FROM vws_materials`;
    try {
      const materials = await db.query(query);
      if (materials.rows && materials.rows.length > 0) {
        return materials.rows;
      }
      return [];
    } catch (error) {
      console.error(
        "Error in findAll: Could not retrieve all materials.",
        error,
      );
      throw new Error("Database error: Failed to fetch all materials.");
    }
  }

  static async findById(id, db = pool) {
    const query = `SELECT * FROM vws_materials WHERE material_id=$1`;
    const values = [id];

    try {
      const materials = await db.query(query, values);
      if (materials.rows && materials.rows.length > 0) {
        return materials.rows[0];
      }
      return null;
    } catch (error) {
      console.error(
        `Error in findById: Could not retrieve material with ID ${id}.`,
        error,
      );
      throw new Error(`Database error: Failed to fetch material by ID ${id}.`);
    }
  }

  // Procedures

  static async create(p_name, p_desc, p_link, db = pool) {
    const query = `CALL proc_create_material($1::character varying, $2::text, $3::text, NULL)`;
    const values = [p_name, p_desc, p_link];

    try {
      const newMaterial = await db.query(query, values);
      if (newMaterial.rows && newMaterial.rows.length > 0) {
        return newMaterial.rows[0].new_material_id;
      }
      return null;
    } catch (error) {
      console.error(
        `Error in create: Could not create new material '${p_name}'.`,
        error,
      );
      if (error.code === "23514") {
        throw new Error(`Material name cannot be empty.`);
      }
      throw new Error(
        "Database error: Failed to execute material creation procedure.",
      );
    }
  }

  static async update(p_id, p_name, p_desc, p_link, db = pool) {
    const query = `CALL proc_update_material($1::integer, $2::character varying, $3::text, $4::text)`;
    const values = [p_id, p_name, p_desc, p_link];
    try {
      await db.query(query, values);
      return true;
    } catch (error) {
      console.error(
        `Error in update: Could not update material with ID ${p_id}.`,
        error,
      );
      if (error.code === "22003") {
        throw new Error(`Material with ID ${p_id} does not exist.`);
      }
      if (error.code === "23514") {
        throw new Error(`Material name cannot be empty.`);
      }
      throw new Error(
        `Database error: Failed to execute material update procedure for ID ${p_id}.`,
      );
    }
  }

  static async delete(p_id, db = pool) {
    const query = `CALL proc_delete_material($1::integer)`;
    const values = [p_id];
    try {
      await db.query(query, values);
      return true;
    } catch (error) {
      console.error(
        `Error in delete: Could not delete material with ID ${p_id}.`,
        error,
      );
      if (error.code === "22003") {
        throw new Error(`Material with ID ${p_id} does not exist.`);
      }
      throw new Error(
        `Database error: Failed to execute material delete procedure for ID ${p_id}.`,
      );
    }
  }
}

export default MaterialModule;
