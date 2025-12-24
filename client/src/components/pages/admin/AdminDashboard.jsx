import React from "react";
import { useUsers } from "../../../hooks/users/queries/useUsers";
import { useClasses } from "../../../hooks/classes/queries/useClasses";
import { useStudents } from "../../../hooks/students/queries/useStudents";
import { useTeachers } from "../../../hooks/teachers/queries/useTeachers";
import { useJournals } from "../../../hooks/journals/queries/useJournals";
import { useParents } from "../../../hooks/parents/queries/useParents";
import { useRoles } from "../../../hooks/roles/queries/useRoles";
import { useSubjects } from "../../../hooks/subjects/queries/useSubjects";
import { useStudentData } from "../../../hooks/studentdata/queries/useStudentData";
import { useLessons } from "../../../hooks/lessons/queries/useLessons";
import { useHomework } from "../../../hooks/homework/queries/useHomework";
import { useTimetables } from "../../../hooks/timetables/queries/useTimetables";
import { useDays } from "../../../hooks/days/queries/useDays";
import { useMaterials } from "../../../hooks/materials/queries/useMaterials";

export default function AdminDashboard() {
  const { data: users, isLoading: usersLoading } = useUsers();
  const { data: classes } = useClasses();
  const { data: students } = useStudents();
  const { data: teachers } = useTeachers();
  const { data: journals } = useJournals();
  const { data: parents } = useParents();
  const { data: roles } = useRoles();
  const { data: subjects } = useSubjects();
  const { data: studentData } = useStudentData();
  const { data: lessons } = useLessons();
  const { data: homework } = useHomework();
  const { data: timetables } = useTimetables();
  const { data: days } = useDays();
  const { data: materials } = useMaterials();

  const cards = [
    { title: 'Users', count: users?.length, loading: usersLoading },
    { title: 'Classes', count: classes?.length },
    { title: 'Students', count: students?.length },
    { title: 'Teachers', count: teachers?.length },
    { title: 'Journals', count: journals?.length },
    { title: 'Parents', count: parents?.length },
    { title: 'Roles', count: roles?.length },
    { title: 'Subjects', count: subjects?.length },
    { title: 'Student Data', count: studentData?.length },
    { title: 'Lessons', count: lessons?.length },
    { title: 'Homework', count: homework?.length },
    { title: 'Timetables', count: timetables?.length },
    { title: 'Days', count: days?.length },
    { title: 'Materials', count: materials?.length },
  ];

  return (
    <main className="main">
        <div className="main__header">
            <h1>Dashboard</h1>
        </div>
        <div className="dashboard-cards" style={{ display: 'grid', gridTemplateColumns: 'repeat(5, 1fr)', gap: '20px' }}>
            {cards.map((card, index) => (
            <div key={index} className="card" style={{ padding: '20px', border: '1px solid #ddd', borderRadius: '8px' }}>
                <h3>{card.title}</h3>
                <p>{card.loading ? 'Loading...' : `Total: ${card.count ?? 0}`}</p>
            </div>
            ))}
        </div>
    </main>
  );
}
