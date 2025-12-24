import ClassModel from "../../lib/models/ClassModel.js";
import pool from "../../lib/db.js";

class ClassService {
  static async getAllClasses(db = pool) {
    try {
      const classes = await ClassModel.findAll(db);
      return { classes };
    } catch (error) {
      console.error("Service Error in getAllClasses:", error.message);
      throw error;
    }
  }

  static async getClassByName(className, db = pool) {
    try {
      const classData = await ClassModel.findByName(className, db);
      if (!classData) {
        throw new Error(`Class with name ${className} not found`);
      }
      return { class: classData };
    } catch (error) {
      console.error("Service Error in getClassByName:", error.message);
      throw error;
    }
  }

  static async getClassAbsentReport(className, amount, db = pool) {
    try {
      const report = await ClassModel.findAbsentReport(className, amount, db);
      return { report };
    } catch (error) {
      console.error("Service Error in getClassAbsentReport:", error.message);
      throw error;
    }
  }

  static async getClassRatingReport(db = pool) {
    try {
      const report = await ClassModel.findRatingReport(db);
      return { report };
    } catch (error) {
      console.error("Service Error in getClassRatingReport:", error.message);
      throw error;
    }
  }

  static async createClass(name, journalId, mainTeacherId, db = pool) {
    try {
      const classData = await ClassModel.create(name, journalId, mainTeacherId, db);
      return { class: classData, message: "Class created successfully" };
    } catch (error) {
      console.error("Service Error in createClass:", error.message);
      throw error;
    }
  }

  static async updateClass(name, journalId, mainTeacherId, newName, db = pool) {
    try {
      const classData = await ClassModel.update(name, journalId, mainTeacherId, newName, db);
      return { class: classData, message: "Class updated successfully" };
    } catch (error) {
      console.error("Service Error in updateClass:", error.message);
      throw error;
    }
  }

  static async deleteClass(name, db = pool) {
    try {
      const result = await ClassModel.delete(name, db);
      return result;
    } catch (error) {
      console.error("Service Error in deleteClass:", error.message);
      throw error;
    }
  }
}

export default ClassService;


