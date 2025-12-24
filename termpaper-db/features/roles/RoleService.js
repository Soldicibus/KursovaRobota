import RolesModel from "../../lib/models/RoleModel.js";
import pool from "../../lib/db.js";

class RoleService {
  static async getAllRoles(db = pool) {
    try {
      const roles = await RolesModel.findAll(db);
      return { roles };
    } catch (error) {
      console.error("Service Error in getAllRoles:", error.message);
      throw error;
    }
  }

  static async getRoleById(roleId, db = pool) {
    try {
      const role = await RolesModel.findById(roleId, db);
      if (!role) {
        throw new Error(`Role with ID ${roleId} not found`);
      }
      return { role };
    } catch (error) {
      console.error("Service Error in getRoleById:", error.message);
      throw error;
    }
  }

  static async createRole(roleName, db = pool) {
    try {
      const role = await RolesModel.create(roleName, db);
      return { role, message: "Role created successfully" };
    } catch (error) {
      console.error("Service Error in createRole:", error.message);
      throw error;
    }
  }

  static async updateRole(roleId, roleName, db = pool) {
    try {
      const role = await RolesModel.update(roleId, roleName, db);
      return { role, message: "Role updated successfully" };
    } catch (error) {
      console.error("Service Error in updateRole:", error.message);
      throw error;
    }
  }

  static async deleteRole(roleId, db = pool) {
    try {
      const result = await RolesModel.delete(roleId, db);
      return result;
    } catch (error) {
      console.error("Service Error in deleteRole:", error.message);
      throw error;
    }
  }
}

export default RoleService;

