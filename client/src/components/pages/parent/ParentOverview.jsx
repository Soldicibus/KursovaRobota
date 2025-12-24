import React, { useState, useEffect, use, useMemo } from "react";
import { useStudentsByParent } from "../../../hooks/students/queries/useStudentByParent";
import { useGetChildren } from "../../../hooks/studentparents/queries/useGetChildren";
import { useUserData } from "../../../hooks/users/queries/useUserData";
import { getCurrentUser } from "../../../utils/auth";
import StudentSchedule from "../student/StudentSchedule";
import StudentGradesAndAbsences from "../student/StudentGradesAndAbsences";
import StudentJournal from "../student/StudentJournal";

export default function ParentOverview() {
  const currentUser = getCurrentUser();
  const userId = currentUser?.userId || currentUser?.id || currentUser?.sub || null;

  const { data: userRes, isLoading: userLoading } = useUserData(userId);
  
  // Unwrap user data safely - handling potential double nesting
  const rawUserData = userRes?.userData ?? userRes?.user ?? userRes ?? null;
  const userData = rawUserData?.userData ?? rawUserData;
  
  const parentId = userData?.entity_id || userData?.entityId || userData?.parent_id || userData?.parentId || null;
  
  if (import.meta.env.DEV) {
    console.log('ParentOverview: userId', userId);
    console.log('ParentOverview: userRes', userRes);
    console.log('ParentOverview: userData (unwrapped)', userData);
    console.log('ParentOverview: parentId', parentId);
  }

  const { data: students, isLoading, error } = useGetChildren(parentId);
  
  if (import.meta.env.DEV) {
    console.log('ParentOverview: students', students);
  }

  const [selectedStudentId, setSelectedStudentId] = useState(null);
  const [activeTab, setActiveTab] = useState("schedule");

  if (import.meta.env.DEV) {
    console.log('ParentOverview: selectedStudentId', selectedStudentId);
  }

  useEffect(() => {
    if (Array.isArray(students) && students.length > 0 && !selectedStudentId) {
      setSelectedStudentId(students[0].id || students[0].student_id);
    }
  }, [students, selectedStudentId]);

  const selectedStudent = Array.isArray(students) 
    ? students.find(s => (s.id || s.student_id) === selectedStudentId) 
    : null;

  return (
    <main className="main">
      <div className="main__header">
        <h1>Кабінет батьків</h1>
      </div>

      <div className="card">
        {isLoading && <div>Завантаження дітей...</div>}
        {error && <div>Помилка завантаження</div>}
        
        {!isLoading && Array.isArray(students) && students.length > 0 ? (
          <div>
            <div style={{ marginBottom: 20 }}>
              <h2>Мої діти</h2>
              <div className="student-selector" style={{ display: "flex", gap: 10, flexWrap: "wrap" }}>
                {students.map((s) => {
                  const sId = s.id || s.student_id;
                  const isSelected = sId === selectedStudentId;
                  return (
                    <button
                      type="button"
                      key={sId}
                      className={isSelected ? "active" : ""}
                      onClick={() => {
                        if (import.meta.env.DEV) console.log("CLICKED student:", sId);
                        setSelectedStudentId(sId);
                      }}
                    >
                      {s.student_name} {s.student_surname} {s.student_class ? `(${s.student_class})` : ""}
                    </button>
                  );
                })}
              </div>
            </div>

            {selectedStudentId && (
              <>
                <div className="tabs" style={{ marginBottom: 16 }}>
                  <button
                    className={activeTab === "schedule" ? "active" : ""}
                    onClick={() => setActiveTab("schedule")}
                  >
                    Розклад
                  </button>
                  <button
                    className={activeTab === "grades" ? "active" : ""}
                    onClick={() => setActiveTab("grades")}
                  >
                    Оцінки та відвідуваність
                  </button>
                  <button
                    className={activeTab === "journal" ? "active" : ""}
                    onClick={() => setActiveTab("journal")}
                  >
                    Журнал
                  </button>
                </div>
                <div style={{ marginTop: 20 }}>
                  {activeTab === "schedule" && (
                    <StudentSchedule studentId={selectedStudentId} />
                  )}
                  {activeTab === "grades" && (
                    <StudentGradesAndAbsences studentId={selectedStudentId} />
                  )}
                  {activeTab === "journal" && (
                    <StudentJournal studentId={selectedStudentId} />
                  )}
                </div>
              </>
            )}
          </div>
        ) : (
          !isLoading && (
            <div>
              <h2>Немає прив'язаних дітей</h2>
              <p>Зверніться до адміністратора для прив'язки учнів до вашого акаунту.</p>
            </div>
          )
        )}
      </div>
    </main>
  );
}
