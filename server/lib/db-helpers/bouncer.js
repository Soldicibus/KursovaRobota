import { Client } from "pg";
import dotenv from "dotenv";
import roleCredentials from "./roleCredentials.js";
dotenv.config();

export const bouncer = async (req, res, work) => {
  // These controllers assume auth middleware has populated req.user.
  // If it didn't, treat as unauthenticated instead of throwing a 500.
  if (!req?.user) {
    console.error("Bouncer: Missing req.user");
    return res.status(401).json({ error: "Unauthorized: missing user context" });
  }

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

  const roleKey = String(dbRole).toLowerCase();
  const credentials = roleCredentials[roleKey];

  if (!credentials) {
    console.error(`Bouncer: No credentials found for role ${dbRole}`);
    return res.status(500).json({ error: "Server Configuration Error: Role credentials missing" });
  }

  const client = new Client({
    host: process.env.DATABASE_HOST,
    port: process.env.DATABASE_PORT ? parseInt(process.env.DATABASE_PORT) : 5432,
    database: process.env.DATABASE_NAME,
    application_name: process.env.DATABASE_APPLICATION_NAME,
    user: credentials.user,
    password: credentials.password,
  });

  try {
    await client.connect();
    
    await client.query("BEGIN");
    
    console.log(`Bouncer: Connected as ${credentials.user} for user ID ${currentUserId}`);
    // Note: We do NOT use SET ROLE anymore, as we are connected as the correct user.
    
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
    // No RESET ROLE needed.
    await client.end();
  }
};

export default bouncer;
