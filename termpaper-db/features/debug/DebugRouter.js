import { Router } from "express";
import { bouncer } from "../../lib/db-helpers/bouncer.js";

const router = Router();

// Returns the *actual* Postgres session identity/role (what privileges apply right now) for the current request.
// This does not query any app tables.
router.get("/db-role", async (req, res) => {
  await bouncer(req, res, async (db) => {
    const { rows } = await db.query(`
      SELECT
        session_user,
        current_user,
        current_role,
        current_setting('role', true) AS role_setting,
        current_setting('app.current_user_id', true) AS app_current_user_id
    `);

    // Optional: quickly show if the current user is superuser (useful for privilege debugging)
    const superUserRes = await db.query("SELECT rolsuper FROM pg_roles WHERE rolname = current_user");
    const isSuperuser = superUserRes.rows?.[0]?.rolsuper ?? null;

    return {
      db: rows?.[0] ?? null,
      isSuperuser,
    };
  });
});

export default router;
