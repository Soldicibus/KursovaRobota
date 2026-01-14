import dotenv from "dotenv";
import { Pool } from "pg";

dotenv.config();
const pool = new Pool({ connectionString: process.env.DATABASE_URL });

async function test() {
  try {
    const res = await pool.query("SELECT NOW()");
    console.log("+ DB Connected:", res.rows[0]);

    const students = await pool.query("SELECT COUNT(*) FROM students");
    console.log("+ Students in DB:", students.rows[0].count);

    const views = await pool.query("SELECT * FROM vw_student_ranking LIMIT 3");
    console.log("+ View works:", views.rows);

    await pool.end();
  } catch (err) {
    console.error("Error:", err.message);
  }
}

test();
