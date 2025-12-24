import { Router } from "express";
import UserRoleController from "./UserRoleController.js";
import authenticateJWT from "../auth/authMiddleware.js";

const router = Router();

// Require auth for all userrole endpoints
router.use(authenticateJWT);

router.get("/", UserRoleController.getAllUserRoles);

// Get all roles for a specific user
router.get("/:userId", UserRoleController.getRolesByUserId);

// Assign a role to a user
router.post("/assign", UserRoleController.assignRole);

// Remove a role from a user
router.delete("/remove", UserRoleController.removeRoleFromUser);

// Get a user's role
router.get("/role/:userId", UserRoleController.getUserRole);

export default router;

