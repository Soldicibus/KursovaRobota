import React, { useEffect, useState } from "react";
import { useHomework } from "../../../hooks/homework/queries/useHomework";
import { useHomeworkByStudentOrClass } from "../../../hooks/homework/queries/useHomeworkByStudentOrClass";
import { useUserData } from "../../../hooks/users/queries/useUserData";
import { getCurrentUser } from "../../../utils/auth";
import { useStudent } from "../../../hooks/students/queries/useStudent";

export default function StudentHomework({ studentId: propStudentId, studentClass: propStudentClass, onSelect }) {
  const [openId, setOpenId] = useState(null);
  const { data: homework, isLoading: homeworkLoading } = useHomework();
  const currentUser = getCurrentUser();
  const userId = currentUser?.userId || currentUser?.id || currentUser?.sub || null;
  const { data: userRes, isLoading: userDataLoading } = useUserData(userId, { enabled: !!userId });
  const userData = userRes?.userData ?? userRes?.user ?? userRes ?? null;

  let resolvedStudentId = propStudentId || userData?.entity_id || userData?.entityId || null;
  const {data: student} = useStudent(resolvedStudentId, { enabled: !!resolvedStudentId });
  let resolvedClass = propStudentClass || student?.student_class || student?.student_class_name || student?.class || null;
  if (!resolvedStudentId && userData) resolvedStudentId = userData?.student_id || userData?.studentId || userData?.entity_id || userData?.entityId || null;
  if (!resolvedClass && userData) resolvedClass = userData?.class || userData?.class_c || userData?.classId || null;

  if (import.meta.env?.VITE_API_DEV === 'true') {
    console.log('student homework: resolvedStudentId, resolvedClass', { userId, resolvedStudentId, resolvedClass, userData, student });
  }

  // If we have a student id, ask the server for homework for this student
  const { data: studentHomework, isLoading: studentHomeworkLoading } = useHomeworkByStudentOrClass(resolvedStudentId, { enabled: !!resolvedStudentId });

  // If server returned homework for student, use it. Otherwise fall back to filtering all homework by class.
  let list = [];
  if (Array.isArray(studentHomework) && studentHomework.length > 0) {
    list = studentHomework;
  } else {
    list = Array.isArray(homework) && homework.length ? homework : [];
    if (resolvedClass) {
      list = list.filter((h) =>
        (h.classId && `${h.classId}` === `${resolvedClass}`) ||
        (h.class_c && `${h.class_c}` === `${resolvedClass}`) ||
        (h.class && `${h.class}` === `${resolvedClass}`)
      );
    }
  }

  const isLoading = homeworkLoading || userDataLoading || studentHomeworkLoading;
  if (import.meta?.env?.DEV) {
    console.log('student homework: resolved', { userId, resolvedStudentId, resolvedClass, listLength: list.length });
  }

  function formatDueDate(d) {
    if (!d) return '—';
    try {
      const date = new Date(d);
      if (Number.isNaN(date.getTime())) return d;
      // Format
      return date.toLocaleString('uk-UA', { year: 'numeric', month: '2-digit', day: '2-digit', hour: '2-digit', minute: '2-digit' });
    } catch (e) {
      return d;
    }
  }

  return (
    <div className="homework-grid">
      {list.map((h, idx) => {
        const cardId = h.homework_id ?? h.id ?? h.homeworkId ?? `tmp-${idx}`;
         return (
           <article
             key={cardId}
             data-card-id={cardId}
             aria-expanded={openId === cardId}
             className={`homework-card ${openId === cardId ? "open" : ""}`}
             onClick={() => {
               const next = openId === cardId ? null : cardId;
               if (import.meta.env?.VITE_API_DEV === 'true') {
                 console.log('[ui] toggling homework card', { clicked: cardId, nextOpen: next });
               }
               setOpenId(next);
               if (onSelect) onSelect(next ? h : null);
             }}
           >
            <header>
              <strong>{h.subject_name || h.subject}</strong>
              <span className="hw-title">{h.homework_name || h.title}</span>
              <div className="hw-meta">
                <span>До: {formatDueDate(h.homework_duedate || h.due)}</span>
                <span>{h.teacher || ''}</span>
              </div>
            </header>

            <div className="hw-body">
              <p>{h.homework_desc || h.desc}</p>
            </div>
          </article>
        );
      })}

      {list.length === 0 && (
        <div className="empty-state">Немає домашніх завдань</div>
      )}
    </div>
  );
}