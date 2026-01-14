import studentService from "./StudentServices.js";
import { bouncer } from "../../lib/db-helpers/bouncer.js";
class StudentController {
  static async getStudents(req, res, next) {
    await bouncer(req, res, async (db) => {
      const { students } = await studentService.getStudents(db);
      return { students };
    });
  }

  static async getStudentsM(req, res, next) {
    await bouncer(req, res, async (db) => {
      const { students } = await studentService.getStudentsM(db);
      return { students };
    });
  }

  static async getStudentById(req, res, next) {
    await bouncer(req, res, async (db) => {
      const { id } = req.params;

      // Validate id is a positive integer to avoid casting errors
      const parsedId = Number(id);
      if (!Number.isInteger(parsedId) || parsedId <= 0) {
        throw new Error("Invalid student id");
      }

      const { student } = await studentService.getStudentById(id, db);
      return { student };
    });
  }
  static async getStudentsAVGAbove7(req, res, next) {
    await bouncer(req, res, async (db) => {
      const { student } = await studentService.getStudentsAVGAbove7(db);
      // this view returns a list under 'student' key from service
      return { students: student };
    });
  }
  static async getStudentsByClass(req, res, next) {
    await bouncer(req, res, async (db) => {
      const { students } = await studentService.getStudentsByClass(db);
      return { students };
    });
  }
  static async getStudentRanking(req, res, next) {
    await bouncer(req, res, async (db) => {
      const { students } = await studentService.getStudentRanking(db);
      return { students };
    });
  }
  static async getStudentsByParent(req, res, next) {
    await bouncer(req, res, async (db) => {
      const { parentId } = req.params;
      const { students } = await studentService.getStudentsByParent(parentId, db);
      return { students };
    });
  }

  static async getStudentGradeAndAbsences(req, res, next) {
    await bouncer(req, res, async (db) => {
      const { studentId, startDate, endDate } = req.query;
      const { students } = await studentService.getStudentGradeAndAbsences(
        studentId,
        startDate,
        endDate,
        db,
      );
      return { students: students || [] };
    });
  }

  static async getStudentMarks(req, res, next) {
    await bouncer(req, res, async (db) => {
      const { studentId, fromDate, toDate } = req.query;
      const { students } = await studentService.getStudentMarks(
        studentId,
        fromDate,
        toDate,
        db,
      );
      return { students };
    });
  }

  static async getStudentAttendanceReport(req, res, next) {
    await bouncer(req, res, async (db) => {
      const studentIdRaw = req.params?.id ?? req.query?.studentId;
      const parsedStudentId = Number(studentIdRaw);
      if (!Number.isInteger(parsedStudentId) || parsedStudentId <= 0) {
        throw new Error("Invalid student id");
      }

      const { fromDate, toDate } = req.query;
      const { report } = await studentService.getStudentAttendanceReport(
        parsedStudentId,
        fromDate,
        toDate,
        db,
      );

      return { report: report || [] };
    });
  }

  static async getStudentPerformanceMatrix(req, res, next) {
    await bouncer(req, res, async (db) => {
      const { studentId } = req.params;
      const { students } = await studentService.getStudentPerformanceMatrix(studentId, db);
      if (!students) {
        throw new Error("Student performance matrix not found");
      }
      return { students };
    });
  }

  static async getStudentDayPlan(req, res, next) {
    await bouncer(req, res, async (db) => {
      const { studentId, fromDate, toDate } = req.query;
      const { day_plan } = await studentService.getStudentDayPlan(
        studentId,
        fromDate,
        toDate,
        db,
      );
      return { day_plan };
    });
  }

  static async addStudent(req, res, next) {
    await bouncer(req, res, async (db) => {
      const { name, surname, patronym, phone, class_c } = req.body;
      const user_id = req.user.userId;

      if (!name || !surname || !phone) {
        throw new Error("name, surname, and phone are required");
      }

      const newStudent = await studentService.addStudent(
        name,
        surname,
        patronym || null,
        phone,
        class_c || null,
        db,
      );
      return { newStudent };
    });
  }
  static async updateStudent(req, res, next) {
    await bouncer(req, res, async (db) => {
      const { name, surname, patronym, phone, class_c } = req.body;
      const id = req.params.id || req.body.id;

      if (!id || !name || !surname || !phone) {
        throw new Error("id, name, surname, and phone are required");
      }

      await studentService.updateStudent(
        id,
        name,
        surname,
        patronym || null,
        phone,
        class_c || null,
        db,
      );
      return { message: "Student has been successfully changed" };
    });
  }
  static async deleteStudent(req, res, next) {
    await bouncer(req, res, async (db) => {
      const { id } = req.params;
      await studentService.deleteStudent(id, db);
      return { message: "Student has been successfully deleted" };
    });
  }

  static async getMonthlyMarks(req, res) {
    try {
      const studentId = parseInt(req.params.studentId);
      const { month } = req.query; // Expect ?month=2023-10-01 or similar

      if (isNaN(studentId)) {
        return res.status(400).json({ message: "Invalid student ID format" });
      }

      const marks = await studentService.getMonthlyMarks(studentId, month);
      res.status(200).json(marks);
    } catch (error) {
      console.error(error);
      res.status(500).json({ message: error.message });
    }
  }
}
export default StudentController;
