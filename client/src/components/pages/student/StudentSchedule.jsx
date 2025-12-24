import React, { useState } from "react";
import { useTimetableByStudent } from "../../../hooks/timetables/queries/useTimetableByStudent";
import { useWeeklyTimetable } from "../../../hooks/timetables/queries/useWeeklyTimetable";
import { useUserData } from "../../../hooks/users/queries/useUserData";
import { getCurrentUser } from "../../../utils/auth";

export default function StudentSchedule({ studentId: propStudentId = null }) {
  if (import.meta.env.DEV) {
    console.log('StudentSchedule: propStudentId', propStudentId);
  }
  const [selectedSubject, setSelectedSubject] = useState(null);
  const days = ['Понеділок','Вівторок','Середа','Четвер','Пʼятниця'];
  const currentUser = getCurrentUser();
  const userId = currentUser?.userId || currentUser?.id || currentUser?.sub || null;
  const { data: userRes, isLoading: userDataLoading } = useUserData(userId, { enabled: !!userId });
  const userData = userRes?.userData ?? userRes?.user ?? userRes ?? null;
  let resolvedStudentId = null;
  if (propStudentId == null) {
    resolvedStudentId = userData?.student_id || userData?.studentId || userData?.entity_id || userData?.entityId || null;
  }
  else {
    resolvedStudentId = propStudentId;
  }

  const { data: timetables, isLoading: timetablesLoading } = useTimetableByStudent(resolvedStudentId, { enabled: !!resolvedStudentId });

  // Extract timetable id defensively from returned shape
  function extractIdFromObj(o) {
    if (!o || typeof o !== 'object') return null;
    if (o.timetable_id || o.id || o.timetableId) return o.timetable_id || o.id || o.timetableId;
    // common DB function key
    if (o.get_timetable_id_by_student_id) return o.get_timetable_id_by_student_id;
    // fallback: find first numeric value in object
    for (const k of Object.keys(o)) {
      const v = o[k];
      if (typeof v === 'number' && Number.isInteger(v)) return v;
      if (typeof v === 'string' && /^[0-9]+$/.test(v)) return parseInt(v, 10);
    }
    return null;
  }

  let timetableId = null;
  if (Array.isArray(timetables) && timetables.length > 0) {
    timetableId = extractIdFromObj(timetables[0]);
  } else if (timetables && Array.isArray(timetables.timetable) && timetables.timetable.length > 0) {
    timetableId = extractIdFromObj(timetables.timetable[0]);
  } else if (timetables && typeof timetables === 'object') {
    timetableId = extractIdFromObj(timetables);
  }

  if (import.meta?.env?.DEV) {
    console.log('student schedule: resolvedStudentId, timetables response', { userId, resolvedStudentId, userData, timetables, timetableId });
  }

  const { data: weekRows, isLoading: weekLoading } = useWeeklyTimetable(timetableId, { enabled: !!timetableId });
  const loading = timetablesLoading || weekLoading;

  function normalizeDayName(s) {
    if (!s) return s;
    // Normalize various apostrophe variants to a single ASCII apostrophe, trim
    return s.replace(/[\u2018\u2019\u02BC\u02BD]/g, "'").trim();
  }

  let sample = {};
  let timesFromData = [];
  if (Array.isArray(weekRows) && weekRows.length > 0) {
    weekRows.forEach(r => {
      const day = normalizeDayName(r.weekday || r.weekday_name || r.day || r.week);
      const t = (r.lesson_time || r.lesson_time || r.lesson || r.time || '').toString().slice(0,5);
      const c = (r.cabinet || r.room || '').toString().trim();
      sample[day] = sample[day] || [];
      sample[day].push({ 
        time: t, 
        cabinet: c,
        subject: r.subject,
        subject_id: r.subject_id,
        teacher: r.teacher || r.teacher_name,
        classroom: r.classroom || r.room,
        lesson_id: r.lesson_id || r.id
      });
      if (t && !timesFromData.includes(t)) timesFromData.push(t);
    });
    timesFromData.sort();
  }

  const timesList = timesFromData.length ? timesFromData : [];

  const handleLessonClick = (lesson) => {
    if (lesson) {
      setSelectedSubject(lesson);
    }
  };

  const closeModal = () => {
    setSelectedSubject(null);
  };

  return (
    <div className="card schedule-card">
      {loading && <div>Завантаження розкладу...</div>}
      <div className="week-grid">
        <div className="week-header">
          <div className="time-col"></div>
          {days.map(d => <div key={d} className="day-col">{d}</div>)}
        </div>

        <div className="week-body">
          {timesList.map(t => (
            <div key={t} className="row">
              <div className="time-col">{t}</div>
              {days.map(d => {
                const dayKey = normalizeDayName(d);
                const found = (sample?.[dayKey] || []).find(e => e.time === t);
                return (
                  <div key={d} className="cell">
                    {found ? (
                      <div 
                        className="lesson" 
                        onClick={() => handleLessonClick(found)}
                        style={{ cursor: 'pointer' }}
                      >
                        <div className="lesson-subject">{found.subject}</div>
                        <div className="lesson-subject">{found.cabinet}</div>
                      </div>
                    ) : null}
                  </div>
                );
              })}
            </div>
          ))}
        </div>
        {!weekLoading && !(Array.isArray(weekRows) && weekRows.length > 0) && <div className="empty-state">Немає розкладу для вашого розкладу</div>}
      </div>

      {selectedSubject && (
        <div 
          className="modal-overlay" 
          onClick={closeModal}
          style={{
            position: 'fixed',
            top: 0,
            left: 0,
            right: 0,
            bottom: 0,
            backgroundColor: 'rgba(0, 0, 0, 0.5)',
            display: 'flex',
            alignItems: 'center',
            justifyContent: 'center',
            zIndex: 1000
          }}
        >
          <div 
            className="modal-content"
            onClick={(e) => e.stopPropagation()}
            style={{
              backgroundColor: 'white',
              padding: '24px',
              borderRadius: '8px',
              maxWidth: '500px',
              width: '90%',
              maxHeight: '80vh',
              overflow: 'auto',
              boxShadow: '0 4px 6px rgba(0, 0, 0, 0.1)'
            }}
          >
            <div style={{ display: 'flex', flexDirection: 'column', gap: '12px' }}>
              {selectedSubject.subject && (
                <div>
                  <strong style={{ color: '#777' }}>Ім'я:</strong>
                  <div style={{ marginTop: '4px', color: '#000000ff' }}>{selectedSubject.subject}</div>
                </div>
              )}
              
              {selectedSubject.time && (
                <div>
                  <strong style={{ color: '#777' }}>Час:</strong>
                  <div style={{ marginTop: '4px', color: '#000000ff' }}>{selectedSubject.time}</div>
                </div>
              )}

              {selectedSubject.cabinet && (
                <div>
                  <strong style={{ color: '#777' }}>Кабінет:</strong>
                  <div style={{ marginTop: '4px', color: '#000000ff' }}>{selectedSubject.cabinet}</div>
                </div>
              )}
            </div>
          </div>
        </div>
      )}
    </div>
  );
}
