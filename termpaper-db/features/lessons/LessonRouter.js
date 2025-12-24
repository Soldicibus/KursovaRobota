import { Router } from "express";
import LessonController from "./LessonController.js";

const router = Router();

router.get("/", LessonController.getAllLessons);
router.get("/:id", LessonController.getLessonById);
router.get("/name/:name", LessonController.getLessonByName);
router.post("/", LessonController.createLesson);
router.patch("/:id", LessonController.updateLesson);
router.delete("/:id", LessonController.deleteLesson);

export default router;

