import TempService from "./tempService.js";
import bouncer from "../../lib/db-helpers/bouncer.js";
class tempController {
  static async getUsers(req, res, next) {
    await bouncer(req, res, async (db) => {
      const users = await TempService.getUsers(db);
      return { users: users.rows, users_count: users.rowCount };
    });
  }
  static async createData(req, res, next) {
    await bouncer(req, res, async (db) => {
      const users = await TempService.createDataSet(db);
      return { users };
    });
  }
  static async assignRoles(req, res, next) {
    await bouncer(req, res, async (db) => {
      const { startFrom, roleId } = req.body;
      const roles = await TempService.assignRoles(startFrom, roleId, db);
      return { result: roles };
    });
  }
  static async assignUserToEntity(req, res, next) {
    await bouncer(req, res, async (db) => {
      const entities = await TempService.assignUsersToEntities(db);
      return { result: entities };
    });
  }
}

export default tempController;
