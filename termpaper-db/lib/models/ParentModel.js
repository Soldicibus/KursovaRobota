import pool from "../db.js";
class ParentModel {
  static async findAll(db = pool) {
    const query = `SELECT * FROM parents`;
    try {
      const parents = await db.query(query);
      if (parents.rows && parents.rows.length > 0) {
        return parents.rows;
      }
      return null;
    } catch (error) {
      console.error(`Database error finding parents`, error);
      throw new Error(
        "Could not retrieve parents data due to a database error.",
      );
    }
  }
  static async findById(id, db = pool) {
    const query = `SELECT * FROM parents WHERE parent_id=$1`;
    const values = [id];

    try {
      const parent = await db.query(query, values);
      if (parent.rows && parent.rows.length > 0) {
        return parent.rows[0];
      }
      return null;
    } catch (error) {
      console.error(`Database error finding parent`, error);
      throw new Error(
        "Could not retrieve parent data due to a database error.",
      );
    }
  }

  // Procedures

  static async create(name, surname, patronym, phone = null, db = pool) {
    const query = `CALL proc_create_parent($1::character varying, $2::character varying, $3::character varying, $4::character varying, NULL::integer, NULL::integer, NULL::text)`;
    const values = [name, surname, patronym, phone];

    try {
      const newParent = await db.query(query, values);
      if (newParent.rows && newParent.rows.length > 0) {
        return newParent.rows;
      }
      return null;
    } catch (error) {
      console.error(
        `Database error creating parent: name=${name}, surname=${surname}, patronym=${patronym}, phone=${phone}`,
        error,
      );
      throw new Error(
        "Could not create parent due to a database error.",
      );
    }
  }
  static async update(id, name, surname, patronym, phone, db = pool) {
    const query = `CALL proc_update_parent($1::integer, $2::character varying, $3::character varying, $4::character varying, $5::character varying, NULL::integer)`;
    const values = [id, name, surname, patronym, phone];

    try {
      await db.query(query, values);
    } catch (error) {
      console.error(
        `Database error updating parent id=${id}: name=${name}, surname=${surname}, patronym=${patronym}, phone=${phone}`,
        error,
      );
      throw new Error(
        "Could not update the parent data due to a database error.",
      );
    }
  }
  static async delete(id, db = pool) {
    const query = `CALL proc_delete_student($1::integer)`;
    const values = [id];

    try {
      await db.query(query, values);
    } catch (error) {
      console.error(`Database error deleting parent id=${id}:`, error);
      throw new Error(
        "Could not delete the parent data due to a database error.",
      );
    }
  }
}
export default ParentModel;
