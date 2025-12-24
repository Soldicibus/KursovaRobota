import { Router } from "express";
import HomeworkController from "./HomeworkController.js";

const router = Router();

router.get("/", HomeworkController.getAllHomework);
router.get("/:id", HomeworkController.getHomeworkById);
router.get("/by-student-or-class/:studentId", HomeworkController.getHomeworkByStudentOrClass);
router.get("/for-tomorrow", HomeworkController.getHomeworkForTomorrow);
router.post("/", HomeworkController.createHomework);
router.patch("/:id", HomeworkController.updateHomework);
router.delete("/:id", HomeworkController.deleteHomework);

export default router;

