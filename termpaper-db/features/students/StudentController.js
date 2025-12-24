import studentService from "./StudentServices.js";
import { bouncer } from "../../lib/db-helpers/bouncer.js";
class StudentController {
  static async getStudents(req, res, next) {
    await bouncer(req, res, async (db) => {
      const { students } = await studentService.getStudents(db);
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
      // Route is /students/attendance/:id
      // Support either :id path param (preferred) or ?studentId=... (legacy)
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
      const newStudent = await studentService.addStudent(
        name,
        surname,
        patronym,
        phone,
        class_c,
        db,
      );
      return { newStudent };
    });
  }
  static async updateStudent(req, res, next) {
    await bouncer(req, res, async (db) => {
      const { name, surname, patronym, phone, class_c } = req.body;
      const id = req.params.id || req.body.id;

      if (!id || !name || !surname || !patronym || !phone) {
        throw new Error("id, name, surname, patronym, and phone are required");
      }

      await studentService.updateStudent(
        id,
        name,
        surname,
        patronym,
        phone,
        class_c,
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
}
export default StudentController;
