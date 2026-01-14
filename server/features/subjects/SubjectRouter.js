import { Router } from "express";
import SubjectController from "./SubjectController.js";

const router = Router();

router.get("/", SubjectController.getAllSubjects);
router.get("/:id", SubjectController.getSubjectById);
router.patch("/:id", SubjectController.updateSubject);
router.post("/", SubjectController.createSubject);
router.delete("/:id", SubjectController.deleteSubject);

export default router;

