import MaterialModule from "../../lib/models/MaterialModel.js";
import pool from "../../lib/db.js";

class MaterialService {
  static async getAllMaterials(db = pool) {
    try {
      const materials = await MaterialModule.findAll(db);
      return { materials };
    } catch (error) {
      console.error("Service Error in getAllMaterials:", error.message);
      throw error;
    }
  }

  static async getMaterialById(materialId, db = pool) {
    try {
      const material = await MaterialModule.findById(materialId, db);
      if (!material) {
        throw new Error(`Material with ID ${materialId} not found`);
      }
      return { material };
    } catch (error) {
      console.error("Service Error in getMaterialById:", error.message);
      throw error;
    }
  }

  static async createMaterial(name, description, link, db = pool) {
    try {
      const materialId = await MaterialModule.create(name, description, link, db);
      return { materialId, message: "Material created successfully" };
    } catch (error) {
      console.error("Service Error in createMaterial:", error.message);
      throw error;
    }
  }

  static async updateMaterial(materialId, name, description, link, db = pool) {
    try {
      await MaterialModule.update(materialId, name, description, link, db);
      return { message: "Material updated successfully" };
    } catch (error) {
      console.error("Service Error in updateMaterial:", error.message);
      throw error;
    }
  }

  static async deleteMaterial(materialId, db = pool) {
    try {
      await MaterialModule.delete(materialId, db);
      return { message: `Material ${materialId} deleted successfully` };
    } catch (error) {
      console.error("Service Error in deleteMaterial:", error.message);
      throw error;
    }
  }
}

export default MaterialService;


