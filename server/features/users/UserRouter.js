import { Router } from "express";
import UserController from "./UserController.js";

const router = Router();

// Get all users
router.get("/", UserController.getAllUsers);

// Get user by ID
router.get("/:id", UserController.getUserById);

// Create a new user
router.post("/", UserController.createUser);

// Update user
router.patch("/:id", UserController.updateUser);

// Delete user
router.delete("/:id", UserController.deleteUser);

// Reset password
router.post("/reset-password", UserController.resetPassword);

// Get user data
router.get("/:id/data", UserController.getUserData);

export default router;

