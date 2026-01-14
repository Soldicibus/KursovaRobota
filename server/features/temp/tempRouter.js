import tempController from "./tempController.js";
import { Router } from "express";

const router = Router();

router.get("/users", tempController.getUsers);
router.post("/data-set", tempController.createData);
router.post("/assign-roles", tempController.assignRoles);
router.post("/assign-entities", tempController.assignUserToEntity);

export default router;
