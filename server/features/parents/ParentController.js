import ParentService from "./ParentService.js";
import bouncer from "../../lib/db-helpers/bouncer.js";

class ParentController {
  static async getAllParents(req, res, next) {
    await bouncer(req, res, async (db) => {
      const result = await ParentService.getAllParents(db);
      return result;
    });
  }

  static async getParentById(req, res, next) {
    await bouncer(req, res, async (db) => {
      const { id } = req.params;

      if (!id) {
        throw new Error("Parent ID is required");
      }

      const result = await ParentService.getParentById(id, db);
      return result;
    });
  }

  static async createParent(req, res, next) {
    await bouncer(req, res, async (db) => {
  const { name, surname, patronym, phone } = req.body;

      if (!name || !surname || !phone) {
        throw new Error("name, surname, and phone are required");
      }

      const result = await ParentService.createParent(
        name,
        surname,
        patronym || null,
        phone,
        db,
      );
      return result;
    });
  }

  static async updateParent(req, res, next) {
    await bouncer(req, res, async (db) => {
  const { id } = req.params;
  const { name, surname, patronym, phone } = req.body;

      if (!id || !name || !surname || !phone) {
        throw new Error("id, name, surname, and phone are required");
      }

      const result = await ParentService.updateParent(
        id,
        name,
        surname,
        patronym || null,
        phone,
        db,
      );
      return result;
    });
  }

  static async deleteParent(req, res, next) {
    await bouncer(req, res, async (db) => {
      const { id } = req.params;

      if (!id) {
        throw new Error("Parent ID is required");
      }

      const result = await ParentService.deleteParent(id, db);
      return result;
    });
  }
}

export default ParentController;
