import pool from "../../lib/db.js";
import StudentModel from "../../lib/models/StudentModel.js";
class StudentServives {
  static async getStudents(db = pool) {
    try {
      const students = await StudentModel.findAll(db);
      return { students };
    } catch (error) {
      console.error({ error: error.message });
    }
  }

  static async getStudentById(id, db = pool) {
    try {
      const student = await StudentModel.findById(id, db);
      return { student };
    } catch (error) {
      console.error({ error: error.message });
    }
  }

  // Views

  static async getStudentsAVGAbove7(db = pool) {
    try {
      const student = await StudentModel.AVGAbove7(db);
      return { student };
    } catch (error) {
      console.error({ error: error.message });
    }
  }
  static async getStudentsByClass(db = pool) {
    try {
      const students = await StudentModel.getByClass(db);
      return { students };
    } catch (error) {
      console.error({ error: error.message });
    }
  }
  static async getStudentRanking(db = pool) {
    try {
      const students = await StudentModel.recieveRanking(db);
      return { students };
    } catch (error) {
      console.error({ error: error.message });
    }
  }

  // Functions

  static async getStudentsByParent(parentId, db = pool) {
    try {
      const students = await StudentModel.findByParentId(parentId, db);
      return { students };
    } catch (error) {
      console.error({ error: error.message });
    }
  }
  static async getStudentGradeAndAbsences(studentId, startDate, endDate, db = pool) {
    try {
      const students = await StudentModel.recieveGradesAndAbsences(
        studentId,
        startDate,
        endDate,
        db,
      );
      return { students };
    } catch (error) {
      console.error({ error: error.message });
    }
  }
  static async getStudentMarks(studentId, fromDate, toDate, db = pool) {
    try {
      const students = await StudentModel.recieveMarks(
        studentId,
        fromDate,
        toDate,
        db,
      );
      return { students };
    } catch (error) {
      console.error({ error: error.message });
    }
  }
  static async getStudentAttendanceReport(studentId, fromDate, toDate, db = pool) {
    try {
      const hasRange = !!fromDate && !!toDate;
      const report = hasRange
        ? await StudentModel.recieveGradesAndAbsences(studentId, fromDate, toDate, db)
        : await StudentModel.recieveAttendanceReport(studentId, db);
      return { report };
    } catch (error) {
      console.error({ error: error.message });
    }
  }
  static async getStudentDayPlan(studentId, fromDate, toDate, db = pool) {
    try {
      const day_plan = await StudentModel.recieveDayPlan(
        studentId,
        fromDate,
        toDate,
        db,
      );
      return { day_plan };
    } catch (error) {
      console.error({ error: error.message });
    }
  }

  // Procedures

  static async addStudent(
    name,
    surname,
    patronym,
    phone,
    class_c,
    db = pool,
  ) {
    try {
      const newStudent = await StudentModel.create(
        name,
        surname,
        patronym,
        phone,
        class_c,
        db,
      );

      return { newStudent };
    } catch (error) {
      console.error({ error: error.message });
    }
  }
  static async updateStudent(
    id,
    name,
    surname,
    patronym,
    phone,
    class_c,
    db = pool,
  ) {
    try {
      await StudentModel.update(
        id,
        name,
        surname,
        patronym,
        phone,
        class_c,
        db,
      );
    } catch (error) {
      console.error({ error: error.message });
    }
  }
  static async deleteStudent(id, db = pool) {
    try {
      await StudentModel.delete(id, db);
    } catch (error) {
      console.error({ error: error.message });
    }
  }
}
export default StudentServives;
