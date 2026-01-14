import pool from "../db.js";

export const bouncer = async (req, res, work) => {
  // These controllers assume auth middleware has populated req.user.
  // If it didn't, treat as unauthenticated instead of throwing a 500.
  if (!req?.user) {
    console.error("Bouncer: Missing req.user");
    return res.status(401).json({ error: "Unauthorized: missing user context" });
  }

  const client = await pool.connect();
  const {
    role,
    role_name: roleName,
    userId,
    user_id: userIdAlt,
    username,
    email,
  } = req.user;

  const dbRole = role ?? roleName;
  const currentUserId = userId ?? userIdAlt;

  if (!dbRole || !currentUserId) {
      console.error("Bouncer: Incomplete user context", req.user);
    return res.status(403).json({ error: "Unauthorized: invalid user context" });
  }

  try {
    await client.query("BEGIN");
    
    // Log connection start (if username is present)
    if (username) {
        try {
            await client.query("SELECT log_app_auth_event($1, $2, $3)", ['CONNECT', username, email || '']);
        } catch (ignore) { /* logging shouldn't kill request */ }
    }
    console.log(`Bouncer: Setting role to ${dbRole} for user ID ${currentUserId}`);
    await client.query(`SET ROLE "${String(dbRole).toLowerCase()}"`);
    console.log(`Bouncer: Role set to ${dbRole}`);
    await client.query(`SELECT set_config('app.current_user_id', $1, true)`, [
      currentUserId.toString(),
    ]);
    if (username) {
      await client.query(`SELECT set_config('app.current_username', $1, true)`, [
        username,
      ]);
    }

    const result = await work(client);

    await client.query("COMMIT");
    return res.json(result);
  } catch (error) {
    await client.query("ROLLBACK");
    if (error.code === "42501")
      return res.status(403).json({ error: "DB: Unauthorized" });
    res.status(500).json({ error: error.message });
  } finally {
    await client.query("RESET ROLE");

    client.release();
  }
};

export default bouncer;
