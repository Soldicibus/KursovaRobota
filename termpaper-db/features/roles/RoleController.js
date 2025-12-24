import RoleService from "./RoleService.js";
import bouncer from "../../lib/db-helpers/bouncer.js";

class RoleController {
  static async getAllRoles(req, res, next) {
    await bouncer(req, res, async (db) => {
      const result = await RoleService.getAllRoles(db);
      return result;
    });
  }

  static async getRoleById(req, res, next) {
    await bouncer(req, res, async (db) => {
      const { id } = req.params;

      if (!id) {
        throw new Error("Role ID is required");
      }

      const result = await RoleService.getRoleById(id, db);
      return result;
    });
  }

  static async createRole(req, res, next) {
    await bouncer(req, res, async (db) => {
      const { roleName } = req.body;

      if (!roleName) {
        throw new Error("roleName is required");
      }

      const result = await RoleService.createRole(roleName, db);
      return result;
    });
  }

  static async updateRole(req, res, next) {
    await bouncer(req, res, async (db) => {
      const { id } = req.params;
      const { roleName } = req.body;

      if (!id || !roleName) {
        throw new Error("id and roleName are required");
      }

      const result = await RoleService.updateRole(id, roleName, db);
      return result;
    });
  }

  static async deleteRole(req, res, next) {
    await bouncer(req, res, async (db) => {
      const { id } = req.params;

      if (!id) {
        throw new Error("Role ID is required");
      }

      const result = await RoleService.deleteRole(id, db);
      return result;
    });
  }
}

export default RoleController;

