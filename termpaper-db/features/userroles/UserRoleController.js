import UserRoleService from "./UserRoleService.js";
import bouncer from "../../lib/db-helpers/bouncer.js";

class UserRoleController {
  static async getRolesByUserId(req, res, next) {
    await bouncer(req, res, async (db) => {
      const { userId } = req.params;

      if (!userId) {
        throw new Error("userId is required");
      }

      const roles = await UserRoleService.getRolesByUserId(userId, db);
      return roles;
    });
  }

  static async getAllUserRoles(req, res, next) {
    await bouncer(req, res, async (db) => {
      const roles = await UserRoleService.getAllUserRoles(db);
      return roles;
    });
  }

  static async assignRole(req, res, next) {
    await bouncer(req, res, async (db) => {
      const { userId, roleId } = req.body;

      if (!userId || !roleId) {
        throw new Error("userId and roleId are required");
      }

      const result = await UserRoleService.assignRole(userId, roleId, db);
      return result;
    });
  }

  static async removeRoleFromUser(req, res, next) {
    await bouncer(req, res, async (db) => {
      const { userId, roleId } = req.body;

      if (!userId || !roleId) {
        throw new Error("userId and roleId are required");
      }

      const result = await UserRoleService.removeRoleFromUser(userId, roleId, db);
      return result;
    });
  }

  static async getUserRole(req, res, next) {
    await bouncer(req, res, async (db) => {
      const { userId } = req.params;
      if (!userId) throw new Error("userId is required");

      const role = await UserRoleService.getUserRole(userId, db);
      return role;
    });
  }
}

export default UserRoleController;

