import React, { useState } from "react";
import { getCurrentUser } from "../../../utils/auth";
import AdminDashboard from "./AdminDashboard";
import UsersTable from "./tables/UsersTable";
import ClassesTable from "./tables/ClassesTable";
import StudentsTable from "./tables/StudentsTable";
import TeachersTable from "./tables/TeachersTable";
import JournalsTable from "./tables/JournalsTable";
import ParentsTable from "./tables/ParentsTable";
import SubjectsTable from "./tables/SubjectsTable";
import StudentDataTable from "./tables/StudentDataTable";
import LessonsTable from "./tables/LessonsTable";
import HomeworkTable from "./tables/HomeworkTable";
import TimetablesTable from "./tables/TimetablesTable";
import DaysTable from "./tables/DaysTable";
import MaterialsTable from "./tables/MaterialsTable";
import "../css/AdminLayout.css";

export default function AdminPanel() {
  const [activeTab, setActiveTab] = useState("dashboard");
  
    const currentUser = getCurrentUser();
    const userId = currentUser?.userId || currentUser?.id || currentUser?.sub || null;
    const userRole = currentUser?.role || currentUser?.role_name || userRes?.role || null;

  if (userRole !== 'admin' && userRole !== 'sadmin') {
    if (import.meta.env?.VITE_API_DEV === 'true') {
      console.warn(`AdminPanel: access denied for role '${userRole}' and userId '${userId || 'unknown'}'`);
    }
    return <main className="main">Доступ заборонено</main>;
  }

  const tabs = [
    { id: 'dashboard', label: 'Dashboard' },
    { id: 'users', label: 'Users' },
    { id: 'classes', label: 'Classes' },
    { id: 'students', label: 'Students' },
    { id: 'teachers', label: 'Teachers' },
    { id: 'journals', label: 'Journals' },
    { id: 'parents', label: 'Parents' },
    { id: 'subjects', label: 'Subjects' },
    { id: 'student-data', label: 'Student Data' },
    { id: 'lessons', label: 'Lessons' },
    { id: 'homework', label: 'Homework' },
    { id: 'timetables', label: 'Timetables' },
    { id: 'days', label: 'Days' },
    { id: 'materials', label: 'Materials' }
  ];

  return (
    <main className="main">
      <div className="main__header">
        <h1>Панель адміністратора</h1>
      </div>

      <div className="tabs" style={{ flexWrap: 'wrap', height: 'auto' }}>
        {tabs.map(tab => (
          <button
            key={tab.id}
            onClick={() => setActiveTab(tab.id)}
            className={activeTab === tab.id ? "active" : ""}
          >
            {tab.label}
          </button>
        ))}
      </div>

      <div className="main__content">
        {activeTab === 'dashboard' && <AdminDashboard />}
        {activeTab === 'users' && <UsersTable />}
        {activeTab === 'classes' && <ClassesTable />}
        {activeTab === 'students' && <StudentsTable />}
        {activeTab === 'teachers' && <TeachersTable />}
        {activeTab === 'journals' && <JournalsTable />}
        {activeTab === 'parents' && <ParentsTable />}
        {activeTab === 'subjects' && <SubjectsTable />}
        {activeTab === 'student-data' && <StudentDataTable />}
        {activeTab === 'lessons' && <LessonsTable />}
        {activeTab === 'homework' && <HomeworkTable />}
        {activeTab === 'timetables' && <TimetablesTable />}
        {activeTab === 'days' && <DaysTable />}
        {activeTab === 'materials' && <MaterialsTable />}
      </div>
    </main>
  );
}

