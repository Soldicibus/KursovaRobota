import { Router } from "express";
import ParentController from "./ParentController.js";

const router = Router();

router.get("/", ParentController.getAllParents);
router.get("/:id", ParentController.getParentById);
router.post("/", ParentController.createParent);
router.patch("/:id", ParentController.updateParent);
router.delete("/:id", ParentController.deleteParent);

export default router;

