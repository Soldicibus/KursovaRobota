import UserRoleModel from "../../lib/models/UserRoleModel.js";
import pool from "../../lib/db.js";

class UserRoleService {
  static async getRolesByUserId(userId, db = pool) {
    try {
      const roles = await UserRoleModel.findRolesByUserId(userId, db);
      return { roles };
    } catch (error) {
      console.error("Service Error in getRolesByUserId:", error.message);
      throw error;
    }
  }

  static async getAllUserRoles(db = pool) {
    try {
      const roles = await UserRoleModel.getAllUserRoles(db);
      return { roles };
    } catch (error) {
      console.error("Service Error in getAllUserRoles:", error.message);
      throw error;
    }
  }

  static async assignRole(userId, roleId, db = pool) {
    try {
      const result = await UserRoleModel.assignRole(userId, roleId, db);
      return { message: `Role ${roleId} assigned to User ${userId}.`, result };
    } catch (error) {
      console.error("Service Error in assignRole:", error.message);
      throw error;
    }
  }

  static async removeRoleFromUser(userId, roleId, db = pool) {
    try {
      const result = await UserRoleModel.removeRoleFromUser(userId, roleId, db);
      return result;
    } catch (error) {
      console.error("Service Error in removeRoleFromUser:", error.message);
      throw error;
    }
  }

  static async getUserRole(userId, db = pool) {
    try {
      const role = await UserRoleModel.getUserRole(userId, db);
      return { role };
    } catch (error) {
      console.error("Service Error in getUserRole:", error.message);
      throw error;
    }
  }
}

export default UserRoleService;

