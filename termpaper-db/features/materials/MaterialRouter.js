import { Router } from "express";
import MaterialController from "./MaterialController.js";

const router = Router();

router.get("/", MaterialController.getAllMaterials);
router.get("/:id", MaterialController.getMaterialById);
router.post("/", MaterialController.createMaterial);
router.patch("/:id", MaterialController.updateMaterial);
router.delete("/:id", MaterialController.deleteMaterial);

export default router;

