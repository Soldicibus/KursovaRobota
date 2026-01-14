import { Router } from "express";
import RoleController from "./RoleController.js";

const router = Router();

// Get all roles
router.get("/", RoleController.getAllRoles);

// Get role by ID
router.get("/:id", RoleController.getRoleById);

// Create a new role
router.post("/", RoleController.createRole);

// Update role
router.patch("/:id", RoleController.updateRole);

// Delete role
router.delete("/:id", RoleController.deleteRole);

export default router;

