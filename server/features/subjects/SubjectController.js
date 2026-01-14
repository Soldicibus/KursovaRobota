import SubjectService from "./SubjectService.js";
import bouncer from "../../lib/db-helpers/bouncer.js";

class SubjectController {
  static async getAllSubjects(req, res, next) {
    await bouncer(req, res, async (db) => {
      const result = await SubjectService.getAllSubjects(db);
      return result;
    });
  }

  static async getSubjectById(req, res, next) {
    await bouncer(req, res, async (db) => {
      const { id } = req.params;

      if (!id) {
        throw new Error("Subject ID is required");
      }

      const result = await SubjectService.getSubjectById(id, db);
      return result;
    });
  }

  static async updateSubject(req, res, next) {
    await bouncer(req, res, async (db) => {
      const { id } = req.params;
      const { name, program, cabinet } = req.body;

      if (!id) {
        throw new Error("Subject ID is required");
      }

      const result = await SubjectService.updateSubject(id, { name, program, cabinet }, db);
      return result;
    });
  }

  static async createSubject(req, res, next) {
    await bouncer(req, res, async (db) => {
      const { name, program, cabinet } = req.body;

      if (!name) {
        throw new Error("name is required");
      }

      const result = await SubjectService.createSubject(name, program || null, cabinet, db);
      return result;
    });
  }

  static async deleteSubject(req, res, next) {
    await bouncer(req, res, async (db) => {
      const { id } = req.params;

      if (!id) {
        throw new Error("Subject ID is required");
      }

      const result = await SubjectService.deleteSubject(id, db);
      return result;
    });
  }
}

export default SubjectController;

