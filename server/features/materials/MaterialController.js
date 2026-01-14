import MaterialService from "./MaterialService.js";
import bouncer from "../../lib/db-helpers/bouncer.js";

class MaterialController {
  static async getAllMaterials(req, res, next) {
    await bouncer(req, res, async (db) => {
      const result = await MaterialService.getAllMaterials(db);
      return result;
    });
  }

  static async getMaterialById(req, res, next) {
    await bouncer(req, res, async (db) => {
      const { id } = req.params;

      if (!id) {
        throw new Error("Material ID is required");
      }

      const result = await MaterialService.getMaterialById(id, db);
      return result;
    });
  }

  static async createMaterial(req, res, next) {
    await bouncer(req, res, async (db) => {
      const { name, description, link } = req.body;

      if (!name) {
        throw new Error("name is required");
      }

      const result = await MaterialService.createMaterial(
        name,
        description || null,
        link || null,
        db,
      );
      return result;
    });
  }

  static async updateMaterial(req, res, next) {
    await bouncer(req, res, async (db) => {
      const { id } = req.params;
      const { name, description, link } = req.body;

      if (!id || !name) {
        throw new Error("id and name are required");
      }

      const result = await MaterialService.updateMaterial(
        id,
        name,
        description || null,
        link || null,
        db,
      );
      return result;
    });
  }

  static async deleteMaterial(req, res, next) {
    await bouncer(req, res, async (db) => {
      const { id } = req.params;

      if (!id) {
        throw new Error("Material ID is required");
      }

      const result = await MaterialService.deleteMaterial(id, db);
      return result;
    });
  }
}

export default MaterialController;

