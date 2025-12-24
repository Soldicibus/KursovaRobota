import JournalService from "./JournalService.js";
import bouncer from "../../lib/db-helpers/bouncer.js";

class JournalController {
  static async getAllJournals(req, res, next) {
    await bouncer(req, res, async (db) => {
      const result = await JournalService.getAllJournals(db);
      return result;
    });
  }

  static async getJournalById(req, res, next) {
    await bouncer(req, res, async (db) => {
      const { id } = req.params;

      if (!id) {
        throw new Error("Journal ID is required");
      }

      const result = await JournalService.getJournalById(id, db);
      return result;
    });
  }

  static async createJournal(req, res, next) {
    await bouncer(req, res, async (db) => {
      const { teacherId, name } = req.body;

      if (!teacherId || !name) {
        throw new Error("teacherId and name are required");
      }

      const result = await JournalService.createJournal(teacherId, name, db);
      return result;
    });
  }

  static async updateJournal(req, res, next) {
    await bouncer(req, res, async (db) => {
      const { id } = req.params;
      const { teacherId, name } = req.body;

      if (!id || !teacherId || !name) {
        throw new Error("id, teacherId, and name are required");
      }

      const result = await JournalService.updateJournal(id, teacherId, name, db);
      return result;
    });
  }

  static async deleteJournal(req, res, next) {
    await bouncer(req, res, async (db) => {
      const { id } = req.params;

      if (!id) {
        throw new Error("Journal ID is required");
      }

      const result = await JournalService.deleteJournal(id, db);
      return result;
    });
  }

  static async getJournalByStudent(req, res, next) {
    await bouncer(req, res, async (db) => {
      const { studentId } = req.params;
      if (!studentId) throw new Error("studentId is required");
      const result = await JournalService.getJournalByStudent(studentId, db);
      return result;
    });
  }
}

export default JournalController;

