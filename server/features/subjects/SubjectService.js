import SubjectsModel from "../../lib/models/SubjectModel.js";
import pool from "../../lib/db.js";

class SubjectService {
  static async getAllSubjects(db = pool) {
    try {
      const subjects = await SubjectsModel.findAll(db);
      return { subjects };
    } catch (error) {
      console.error("Service Error in getAllSubjects:", error.message);
      throw error;
    }
  }

  static async getSubjectById(subjectId, db = pool) {
    try {
      const subject = await SubjectsModel.findById(subjectId, db);
      if (!subject) {
        throw new Error(`Subject with ID ${subjectId} not found`);
      }

      return { subject };
    } catch (error) {
      console.error("Service Error in getSubjectById:", error.message);
      throw error;
    }
  }
  static async updateSubject(subjectId, { name, program, cabinet }, db = pool) {
    try {
      const updatedSubject = await SubjectsModel.update(subjectId, name, program, cabinet, db);
      if (!updatedSubject) {
        throw new Error(`Subject with ID ${subjectId} not found`);
      }

      return { subject: updatedSubject };
    } catch (error) {
      console.error("Service Error in updateSubject:", error.message);
      throw error;
    }
  }

  static async createSubject(name, program, cabinet, db = pool) {
    if (!name) {
      throw new Error("name is required");
    }
    try {
      const subject = await SubjectsModel.create(name, program || null, cabinet || 100, db);
      return { subject, message: "Subject created successfully" };
    } catch (error) {
      console.error("Service Error in createSubject:", error.message);
      throw error;
    }
  }

  static async deleteSubject(subjectId, db = pool) {
    try {
      const result = await SubjectsModel.delete(subjectId, db);
      return result;
    } catch (error) {
      console.error("Service Error in deleteSubject:", error.message);
      throw error;
    }
  }
}

export default SubjectService;


