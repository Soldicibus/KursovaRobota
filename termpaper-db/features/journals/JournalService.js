import JournalModel from "../../lib/models/JournalModel.js";
import pool from "../../lib/db.js";

class JournalService {
  static async getAllJournals(db = pool) {
    try {
      const journals = await JournalModel.findAll(db);
      return { journals };
    } catch (error) {
      console.error("Service Error in getAllJournals:", error.message);
      throw error;
    }
  }

  static async getJournalById(journalId, db = pool) {
    try {
      const journal = await JournalModel.findById(journalId, db);
      if (!journal) {
        throw new Error(`Journal with ID ${journalId} not found`);
      }
      return { journal };
    } catch (error) {
      console.error("Service Error in getJournalById:", error.message);
      throw error;
    }
  }

  static async createJournal(teacherId, name, db = pool) {
    try {
      const journal = await JournalModel.create(teacherId, name, db);
      return { journal, message: "Journal created successfully" };
    } catch (error) {
      console.error("Service Error in createJournal:", error.message);
      throw error;
    }
  }

  static async updateJournal(journalId, teacherId, name, db = pool) {
    try {
      const journal = await JournalModel.update(journalId, teacherId, name, db);
      return { journal, message: "Journal updated successfully" };
    } catch (error) {
      console.error("Service Error in updateJournal:", error.message);
      throw error;
    }
  }

  static async deleteJournal(journalId, db = pool) {
    try {
      const result = await JournalModel.delete(journalId, db);
      return result;
    } catch (error) {
      console.error("Service Error in deleteJournal:", error.message);
      throw error;
    }
  }

  static async getJournalByStudent(studentId, db = pool) {
    try {
      const entries = await JournalModel.findByStudentId(studentId, db);
      return { entries };
    } catch (error) {
      console.error("Service Error in getJournalByStudent:", error.message);
      throw error;
    }
  }
}

export default JournalService;


