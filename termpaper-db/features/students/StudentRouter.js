import { Router } from "express";
import studentController from "./StudentController.js";

const router = Router();

// Specific routes first (avoid matching :id)
router.get("/", studentController.getStudents);
router.get("/avg-above-7", studentController.getStudentsAVGAbove7);
router.get("/class", studentController.getStudentsByClass);
router.get("/ranking", studentController.getStudentRanking);
router.get("/by-parent/:parentId", studentController.getStudentsByParent);
router.get("/grades-and-absences/:id", studentController.getStudentGradeAndAbsences);
router.get("/marks", studentController.getStudentMarks);
router.get("/attendance/:id", studentController.getStudentAttendanceReport);
router.get("/day-plan", studentController.getStudentDayPlan);

// CRUD
router.post("/", studentController.addStudent);
router.patch("/:id", studentController.updateStudent);
router.delete("/:id", studentController.deleteStudent);

// Param route last
router.get("/:id", studentController.getStudentById);

export default router;
