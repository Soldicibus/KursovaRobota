import UserModel from "../../lib/models/UserModel.js";
import pool from "../../lib/db.js";

class UserService {
  static async getAllUsers(db = pool) {
    try {
      const users = await UserModel.findAll(db);
      return { users };
    } catch (error) {
      console.error("Service Error in getAllUsers:", error.message);
      throw error;
    }
  }

  static async getUserById(userId, db = pool) {
    try {
      const user = await UserModel.findById(userId, db);
      if (!user) {
        throw new Error(`User with ID ${userId} not found`);
      }
      return { user };
    } catch (error) {
      console.error("Service Error in getUserById:", error.message);
      throw error;
    }
  }

  static async createUser(username, email, password, db = pool) {
    try {
      const userId = await UserModel.create(username, email, password, db);
      return { userId, message: "User created successfully" };
    } catch (error) {
      console.error("Service Error in createUser:", error.message);
      throw error;
    }
  }

  static async updateUser(userId, username, email, password, db = pool) {
    try {
      await UserModel.update(userId, username, email, password, db);
      return { message: "User updated successfully" };
    } catch (error) {
      console.error("Service Error in updateUser:", error.message);
      throw error;
    }
  }

  static async deleteUser(userId, db = pool) {
    try {
      await UserModel.delete(userId, db);
      return { message: `User ${userId} deleted successfully` };
    } catch (error) {
      console.error("Service Error in deleteUser:", error.message);
      throw error;
    }
  }

  static async resetPassword(userId, newPassword, db = pool) {
    try {
      await UserModel.reset_password(userId, newPassword, db);
      return { message: "Password reset successfully" };
    } catch (error) {
      console.error("Service Error in resetPassword:", error.message);
      throw error;
    }
  }

  static async getUserData(userId, db = pool) {
    try {
      const userData = await UserModel.getUserData(userId, db);
      return { userData };
    } catch (error) {
      console.error("Service Error in getUserData:", error.message);
      throw error;
    }
  }
}

export default UserService;

