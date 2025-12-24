import { Router } from "express";
import StudentParentController from "./StudentParentController.js";

const router = Router();

router.get("/:studentId", StudentParentController.getParentsByStudentId);
router.get("/children/:parentId", StudentParentController.getChildren);
router.post("/assign", StudentParentController.assignParentToStudent);
router.delete("/unassign", StudentParentController.unassignParentFromStudent);

export default router;

