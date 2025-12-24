import SubjectService from "./SubjectService.js";
import bouncer from "../../lib/db-helpers/bouncer.js";

class SubjectController {
  static async getAllSubjects(req, res, next) {
    await bouncer(req, res, async (db) => {
      const result = await SubjectService.getAllSubjects(db);
      return result;
    });
  }

  static async createSubject(req, res, next) {
    await bouncer(req, res, async (db) => {
      const { name, program } = req.body;

      if (!name || !program) {
        throw new Error("name and program are required");
      }

      const result = await SubjectService.createSubject(name, program, db);
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

