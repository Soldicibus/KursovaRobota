import { Router } from "express";
import ClassController from "./ClassController.js";

const router = Router();

router.get("/", ClassController.getAllClasses);
router.get("/:name", ClassController.getClassByName);
router.get("/rate/rating", ClassController.getClassRatingReport);
router.get("/absent/:name/:amount", ClassController.getClassAbsentReport);
router.post("/", ClassController.createClass);
router.patch("/:name", ClassController.updateClass);
router.delete("/:name", ClassController.deleteClass);

export default router;

