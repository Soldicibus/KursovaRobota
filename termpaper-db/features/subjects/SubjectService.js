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

  static async createSubject(name, program, db = pool) {
    try {
      const subject = await SubjectsModel.create(name, program, db);
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


