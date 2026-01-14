import pool from "../../lib/db.js";
import tempUtils from "./tempUtils.js";
class TempService {
  static async getUsers(db = pool) {
    const users = await db.query(`SELECT * FROM users`);

    return users;
  }

  static async createDataSet(db = pool) {
    const users = await db.query(`SELECT * FROM teacher`);

    users.rows.forEach((u) => {
      u.teacher_name = tempUtils.tranlateToLatin(u.teacher_name);
      u.teacher_surname = tempUtils.tranlateToLatin(u.teacher_surname);
      u.teacher_patronym = tempUtils.tranlateToLatin(u.teacher_patronym);
    });

    Promise.all([
      users.rows.map(async (u) => {
        let password = await tempUtils.hashPassword(
          tempUtils.generatePassword(),
        );
        let user = await db.query(
          `CALL proc_create_user($1::character varying, $2::character varying, $3::character varying, null)`,
          [
            u.teacher_surname + u.teacher_name + u.teacher_patronym,
            u.teacher_surname +
              u.teacher_name +
              u.teacher_patronym +
              "@school.ua",
            password,
          ],
        );

        await db.query(
          `CALL proc_assign_user_to_entity($1::integer, 'teacher'::text, $2::integer)`,
          [user.rows[0].new_user_id, u.teacher_id],
        );
      }),
    ]);

    /*const new_users = await Promise.all(
      users.rows.map(async (u) => {
        return {
          name: u.parent_surname + u.parent_name,
          email: u.parent_surname + u.parent_name + "@shool.ua",
          password: await tempUtils.hashPassword(tempUtils.generatePassword()),
        };
      }),
    );*/

    const result = await db.query(`SELECT * FROM users`);

    return result.rows;
  }

  static async createTestUser(db = pool) {
  // 1. Setup specific test data
  const rawData = {
    name: "sniffy2",
    surname: "",
    patronym: ""
  };

  // 2. Translate to Latin using your existing utility
  const latName = tempUtils.tranlateToLatin(rawData.name);
  const latSurname = tempUtils.tranlateToLatin(rawData.surname);
  const latPatronym = tempUtils.tranlateToLatin(rawData.patronym);

  
  const rawPassword = 'Test1234!';
  console.log(`--- TEST USER CREATED ---`);
  console.log(`Login/Email: ${latSurname}${latName}${latPatronym}@school.ua`);
  console.log(`Password: ${rawPassword}`);
  console.log(`-------------------------`);

  const hashedPassword = await tempUtils.hashPassword(rawPassword);

  try {
    const userResult = await db.query(
      `CALL proc_create_user($1::character varying, $2::character varying, $3::character varying, null)`,
      [
        latSurname + latName + latPatronym,
        latSurname + latName + latPatronym + "@school.ua",
        hashedPassword,
      ]
    );

    const newUserId = userResult.rows[0].new_user_id;

    await db.query(
      `CALL proc_assign_user_to_entity($1::integer, 'teacher'::text, $2::integer)`,
      [newUserId, 1] 
    );

    return { success: true, email: `${latSurname}${latName}${latPatronym}@school.ua`, password: rawPassword };
  } catch (err) {
    console.error("Error creating test user:", err);
  }
}

  static async assignRoles(startFrom = 0, roleId, db = pool) {
    const users = await db.query(`SELECT * FROM users`);

    Promise.all(
      users.rows.slice(startFrom).map((u) => {
        return db.query(
          `CALL proc_assign_role_to_user($1::integer, $2::integer)`,
          [u.user_id, roleId],
        );
      }),
    );
    const result = await db.query(`SELECT * FROM userrole`);
    return result.rows;
  }

  static async assignUsersToEntities(startFrom = 468, db = pool) {
    const users = await db.query(`SELECT * FROM users`);
    const students = await db.query(`SELECT * FROM students`);

    Promise.all(
      users.rows.slice(startFrom).map((u, i) => {
        return db.query(
          `CALL proc_assign_user_to_entity($1::integer, 'student'::text, $2::integer)`,
          [u.user_id, students.rows[i].student_id],
        );
      }),
    );
    const result = await db.query(`SELECT * FROM students`);
    return result.rows;
  }
}
export default new TempService();
