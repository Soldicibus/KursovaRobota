import authService from "./authService.js";
import bouncer from "../../lib/db-helpers/bouncer.js";

class AuthController {
  static async login(req, res, next) {
    try {
      if (!req.body || Object.keys(req.body).length === 0) {
        return res.status(400).json({ error: "Missing JSON body." });
      }

      const { username, email, password } = req.body;
      if (!username && !email)
        return res.status(400).json({ error: "username or email required" });
      if (!password)
        return res.status(400).json({ error: "password required" });

      const tokens = await authService.login(username, email, password);
      res.json(tokens);
    } catch (error) {
      res.status(401).json({ error: error.message });
    }
  }

  static async refresh(req, res, next) {
    try {
      const { refreshToken: oldToken } = req.body || {};
      if (!oldToken) return res.status(400).json({ error: "Missing refresh token" });

      const newAccessToken = authService.refreshToken(oldToken);
      return res.json({ accessToken: newAccessToken });
    } catch (error) {
      return res.status(401).json({ error: error.message });
    }
  }

  static async me(req, res) {
    await bouncer(req, res, async (db) => {
      if (!req.user) throw new Error("Unauthorized");
      const id = req.user.userId ?? req.user.id;
      const role = req.user.role;
      if (!id || !role)
        throw new Error("Token missing critical identity fields");

      return { user: { id, role } };
    });
  }

  static async register(req, res, next) {
    try {
      const { username, email, password } = req.body;
      if (!username || !email || !password)
        return res.status(400).json({ error: "All fields required" });

      const tokens = await authService.register(username, email, password);
      res.status(201).json(tokens);
    } catch (error) {
      if (error.code === "23505")
        return res.status(409).json({ error: "User already exists" });
      res.status(400).json({ error: error.message });
    }
  }

  static async switchRole(req, res) {
    await bouncer(req, res, async (db) => {
      const { targetRole } = req.body;
      if (!targetRole) throw new Error("targetRole required");

      const userId = req.user.userId;
      const result = await authService.switchRole(userId, targetRole);
      return result;
    });
  }
}

export default AuthController;
