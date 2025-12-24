import ParentModel from "../../lib/models/ParentModel.js";
import pool from "../../lib/db.js";

class ParentService {
  static async getAllParents(db = pool) {
    try {
      const parents = await ParentModel.findAll(db);
      return { parents };
    } catch (error) {
      console.error("Service Error in getAllParents:", error.message);
      throw error;
    }
  }

  static async getParentById(parentId, db = pool) {
    try {
      const parent = await ParentModel.findById(parentId, db);
      if (!parent) {
        throw new Error(`Parent with ID ${parentId} not found`);
      }
      return { parent };
    } catch (error) {
      console.error("Service Error in getParentById:", error.message);
      throw error;
    }
  }

  static async createParent(name, surname, patronym, phone, db = pool) {
    try {
      const parentId = await ParentModel.create(
        name,
        surname,
        patronym,
        phone,
        db,
      );
      return { parentId, message: "Parent created successfully" };
    } catch (error) {
      console.error("Service Error in createParent:", error.message);
      throw error;
    }
  }

  static async updateParent(
    parentId,
    name,
    surname,
    patronym,
    phone,
    db = pool,
  ) {
    try {
      await ParentModel.update(
        parentId,
        name,
        surname,
        patronym,
        phone,
        db,
      );
      return { message: "Parent updated successfully" };
    } catch (error) {
      console.error("Service Error in updateParent:", error.message);
      throw error;
    }
  }

  static async deleteParent(parentId, db = pool) {
    try {
      await ParentModel.delete(parentId, db);
      return { message: `Parent ${parentId} deleted successfully` };
    } catch (error) {
      console.error("Service Error in deleteParent:", error.message);
      throw error;
    }
  }
}

export default ParentService;
