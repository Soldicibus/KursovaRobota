import ClassService from "./ClassService.js";
import { bouncer } from "../../lib/db-helpers/bouncer.js";

class ClassController {
  static async getAllClasses(req, res, next) {
    await bouncer(req, res, async (db) => {
      const result = await ClassService.getAllClasses(db);
      return result;
    });
  }

  static async getClassByName(req, res, next) {
    await bouncer(req, res, async (db) => {
      const { name } = req.params;

      if (!name) {
        throw new Error("Class name is required");
      }

      const result = await ClassService.getClassByName(name, db);
      return result;
    });
  }

  static async getClassAbsentReport(req, res, next) {
    await bouncer(req, res, async (db) => {
      const { name, amount } = req.params;
      if (!name || !amount) {
        throw new Error("Class name and amount are required");
      }

      const result = await ClassService.getClassAbsentReport(name, amount, db);
      return result;
    });
  }

  static async getClassRatingReport(req, res, next) {
    await bouncer(req, res, async (db) => {
      const result = await ClassService.getClassRatingReport(db);
      return result;
    });
  }

  static async createClass(req, res, next) {
    await bouncer(req, res, async (db) => {
      const { name, journalId, mainTeacherId } = req.body;

      if (!name) {
        throw new Error("name is required");
      }

      const result = await ClassService.createClass(
        name,
        journalId || null,
        mainTeacherId || null,
        db,
      );
      return result;
    });
  }

  static async updateClass(req, res, next) {
    await bouncer(req, res, async (db) => {
      const { name, journalId, mainTeacherId, newName } = req.body;

      if (!name) {
        throw new Error("name is required");
      }

      const result = await ClassService.updateClass(name, journalId || null, mainTeacherId || null, newName, db);
      return result;
    });
  }

  static async deleteClass(req, res, next) {
    await bouncer(req, res, async (db) => {
      const { name } = req.params;

      if (!name) {
        throw new Error("Class name is required");
      }

      const result = await ClassService.deleteClass(name, db);
      return result;
    });
  }
}

export default ClassController;

