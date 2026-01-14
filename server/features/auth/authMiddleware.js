import jwt from "jsonwebtoken";

export function authenticateJWT(req, res, next) {
  const authHeader = req.headers.authorization;

  if (!authHeader) {
    return res.status(401).json({ error: "Missing Authorization header" });
  }

  const [type, token] = authHeader.split(" ");

  if (type !== "Bearer" || !token) {
    return res.status(401).json({ error: "Invalid Authorization format" });
  }

  try {
    const payload = jwt.verify(token, process.env.JWT_SECRET);
    const userId = payload?.userId ?? payload?.user_id ?? payload?.sub;
    const roleName = payload?.role_name ?? payload?.role;

    if (!payload || !userId || !roleName) {
      return res.status(401).json({ error: "Invalid token payload" });
    }

    // Normalize fields expected by controllers/helpers.
    req.user = {
      ...payload,
      userId,
      role: payload?.role ?? roleName,
      role_name: roleName,
    };

    next();
  } catch (err) {
    if (err.name === "TokenExpiredError") {
      return res.status(401).json({ error: "Token expired" });
    }

    return res.status(401).json({ error: "Invalid token" });
  }
}
export default authenticateJWT;
