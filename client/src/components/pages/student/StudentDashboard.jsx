import React, { useState } from "react";
import "../css/Dashboard.css";
import StudentJournal from "./StudentJournal";
import StudentHomework from "./StudentHomework";
import StudentSchedule from "./StudentSchedule";
import StudentMaterials from "./StudentMaterials";
import StudentGradesAndAbsences from "./StudentGradesAndAbsences";
import StudentRanking from "./StudentRanking";
import { useStudents } from "../../../hooks/students/queries/useStudents";
import { useStudent } from "../../../hooks/students/queries/useStudent";
import { useUserData } from "../../../hooks/users/queries/useUserData";
import { getCurrentUser } from "../../../utils/auth";

export default function StudentDashboard() {
  const [tab, setTab] = useState("journal");
  const { data: students, isLoading: studentsLoading } = useStudents();
  // Derive user id from token and fetch user profile to obtain linked student id
  const currentUser = getCurrentUser();
  const userId = currentUser?.userId || currentUser?.id || currentUser?.sub || null;
  const userRole = currentUser?.role || currentUser?.role_name || userRes?.role || null;
  // Check if user has student role
  const hasStudentRole = typeof userRole === 'string' && userRole.toLowerCase() === 'student';
  const { data: userRes, isLoading: userLoading } = useUserData(userId);
  const userData = userRes?.userData ?? userRes?.user ?? userRes ?? null;

  // support new `entity_id` returned by /users/:id/data (mapped to student/teacher/parent)
  const linkedStudentId = userData?.entity_id || userData?.entityId || null;
  const { data: student, isLoading: studentLoading } = useStudent(linkedStudentId);

  const className =
    student?.student_class ||
    student?.student_class_name ||
    student?.class ||
    userData?.student_class ||
    userData?.class ||
    userData?.class_name ||
    '—';

  // normalize display fields from userData
  function pickName(u) {
    if (!u) return { name: null, surname: null, email: null, phone: null };
    // Prefer student-specific fields when available
    const name = u.student_name || u.name || u.username || null;
    const surname = u.student_surname || u.surname || null;
    const patronym = u.student_patronym || u.patronym || u.middle_name || null;
    const email = u.student_email || u.email || u.user_email || u.contact_email || null;
    const phone = u.student_phone || u.phone || u.mobile || u.telephone || u.contact_phone || null;
    return { name, surname, email, phone };
  }
  const { name: userName, surname: userSurname, email: userEmail, phone: userPhone } = pickName(userData);
  const userPatronym = userData?.student_patronym || userData?.patronym || userData?.middle_name || null;
  let studentsList = [];
  //console.log('students', students);
  //console.log(Array.isArray(students));
  if (Array.isArray(students)) {
    studentsList = students;
  }
  const studentsCount = Array.isArray(studentsList) ? studentsList.length : null;

  if (import.meta.env?.VITE_API_DEV === 'true') {
    console.log('DEBUG: StudentDashboard render', { userId, linkedStudentId, hasStudentRole, userData, student, studentsCount });
  }

  return (
    <main className="main">
      <div className="main__header">
        <h1>Кабінет учня</h1>
      </div>

      <div className="main__content">
        <div className="card small">
          {userLoading ? (
            <div>Завантаження інформації учнів...</div>
          ) : (
            <h2>Загалом учнів у системі: {studentsCount ?? 0}</h2>
          )}
        </div>

        <div className="card">
          {userLoading ? (
            <div>Завантаження профілю користувача...</div>
          ) : !linkedStudentId && !hasStudentRole ? (
            <div>
              <p>Ваш обліковий запис не пов'язаний з профілем учня. Зверніться до адміністратора.</p>
              <details style={{ marginTop: 8 }}>
                <summary>Діагностика (натисніть)</summary>
                <div style={{ fontSize: 12, marginTop: 8 }}>
                  <div><strong>userId from token:</strong> {String(userId)}</div>
                  <div><strong>userData:</strong></div>
                  <pre style={{ whiteSpace: 'pre-wrap' }}>{JSON.stringify(userData, null, 2)}</pre>
                  <div><strong>userRoles:</strong></div>
                  <pre style={{ whiteSpace: 'pre-wrap' }}>{JSON.stringify(userRoles, null, 2)}</pre>
                </div>
              </details>
            </div>
          ) : !linkedStudentId && hasStudentRole ? (
             // show profile from userData even if not linked, and indicate automatic lookup status
             <div>
              <h2>{userName || userData?.name || '—'} {userPatronym ? `${userPatronym}` : ''} {userSurname || userData?.surname || ''}</h2>
              <p>Клас: {className}</p>
               {linkedStudentId && <div style={{ marginTop: 6, fontSize: 13, color: '#666' }}>Знайдено entity_id: {linkedStudentId} — використовується для зв'язування з профілем учня.</div>}
              <p>Телефон: {userPhone || '—'}</p>
              <p>Пошта: {userEmail || '—'}</p>
             </div>
           ) : studentLoading ? (
             <div>Завантаження профілю учня...</div>
           ) : student ? (
             <div>
              <h2>{student.name || userName || student.student_name} {student.patronym || userPatronym || student.student_patronym || ''} {student.surname || userSurname || student.student_surname}</h2>
              <p>Клас: {className}</p>
              <p>Телефон: {student.phone || student.student_phone || userPhone || '—'}</p>
              <p>Пошта: {student.email || student.student_email || userEmail || '—'}</p>
             </div>
           ) : (
            <div>Немає профілю учня (увійдіть або зв'яжіться з адміністратором)</div>
          )}
        </div>
      </div>

      <div className="tabs">
        <button
          onClick={() => setTab("journal")}
          className={tab === "journal" ? "active" : ""}
        >
          Журнал
        </button>
        <button
          onClick={() => setTab("homework")}
          className={tab === "homework" ? "active" : ""}
        >
          Домашні
        </button>
        <button
          onClick={() => setTab("schedule")}
          className={tab === "schedule" ? "active" : ""}
        >
          Розклад
        </button>
        <button
          onClick={() => setTab("materials")}
          className={tab === "materials" ? "active" : ""}
        >
          Матеріали
        </button>
        <button
          onClick={() => setTab("grades")}
          className={tab === "grades" ? "active" : ""}
        >
          Звітність
        </button>
        <button
          onClick={() => setTab("ranking")}
          className={tab === "ranking" ? "active" : ""}
        >
          Рейтинг
        </button>
      </div>

      <div className="tab-content">
        {tab === "journal" && <StudentJournal studentId={linkedStudentId} />}
        {tab === "homework" && <StudentHomework studentId={linkedStudentId} studentClass={className} />}
        {tab === "schedule" && <StudentSchedule studentClass={className} />}
        {tab === "materials" && <StudentMaterials studentClass={className} />}
        {tab === "grades" && <StudentGradesAndAbsences enabled={true} studentId={linkedStudentId} />}
        {tab === "ranking" && <StudentRanking />}
      </div>
    </main>
  );
}
