import UserService from "./UserService.js";
import { bouncer } from "../../lib/db-helpers/bouncer.js";

class UserController {
  static async getAllUsers(req, res, next) {
    await bouncer(req, res, async (db) => {
      const result = await UserService.getAllUsers(db);
      return result;
    });
  }

  static async getUserById(req, res, next) {
    await bouncer(req, res, async (db) => {
      const { id } = req.params;

      if (!id) {
        throw new Error("User ID is required");
      }

      const result = await UserService.getUserById(id, db);
      return result;
    });
  }

  static async createUser(req, res, next) {
    await bouncer(req, res, async (db) => {
      const { username, email, password } = req.body;

      if (!username || !email || !password) {
        throw new Error("username, email, and password are required");
      }

      const result = await UserService.createUser(username, email, password, db);
      return result;
    });
  }

  static async updateUser(req, res, next) {
    await bouncer(req, res, async (db) => {
      const { id } = req.params;
      const { username, email, password } = req.body;

      if (!id || !username || !email) {
        throw new Error("id, username, and email are required");
      }

      const result = await UserService.updateUser(id, username, email, password, db);
      return result;
    });
  }

  static async deleteUser(req, res, next) {
    await bouncer(req, res, async (db) => {
      const { id } = req.params;

      if (!id) {
        throw new Error("User ID is required");
      }

      const result = await UserService.deleteUser(id, db);
      return result;
    });
  }

  static async resetPassword(req, res, next) {
    await bouncer(req, res, async (db) => {
      const { userId, newPassword } = req.body;

      if (!userId || !newPassword) {
        throw new Error("userId and newPassword are required");
      }

      const result = await UserService.resetPassword(userId, newPassword, db);
      return result;
    });
  }

  static async getUserData(req, res, next) {
    await bouncer(req, res, async (db) => {
      const { id } = req.params;
      if (!id) {
        throw new Error("User ID is required");
      }
      const result = await UserService.getUserData(id, db);
      return result;
    });
  }
}

export default UserController;

