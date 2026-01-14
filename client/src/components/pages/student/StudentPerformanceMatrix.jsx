import React from "react";
import { useStudentPerformanceMatrix } from "../../../hooks/students/queries/useStudentPerformanceMatrix";
import { useUserData } from "../../../hooks/users/queries/useUserData";
import { useStudent } from "../../../hooks/students/queries/useStudent";
import { getCurrentUser } from "../../../utils/auth";

export default function StudentPerformanceMatrix({ studentId: propStudentId }) {
  const currentUser = getCurrentUser();
  const userId = currentUser?.userId || currentUser?.id || currentUser?.sub || null;
  const { data: userRes, isLoading: userDataLoading } = useUserData(userId, { enabled: !!userId });
  const userData = userRes?.userData ?? userRes?.user ?? userRes ?? null;

  let resolvedStudentId = propStudentId || userData?.entity_id || userData?.entityId || null;
  const { data: student } = useStudent(resolvedStudentId, { enabled: !!resolvedStudentId });
  if (!resolvedStudentId && userData) {
    resolvedStudentId = userData?.student_id || userData?.studentId || userData?.entity_id || userData?.entityId || null;
  } else if (!resolvedStudentId && !userData && student) {
    resolvedStudentId = student?.id || student?.entity_id || student?.entityId || null;
  }

  const { data: performanceData, isLoading, isError } = useStudentPerformanceMatrix(resolvedStudentId);

  const loading = userDataLoading || isLoading;
  if (loading) return <div>Завантаження матриці успішності...</div>;
  if (isError) return <div>Помилка завантаження матриці успішності</div>;
  if (!resolvedStudentId) return <div>Не знайдено ID учня</div>;

  // API may return an object, an array, or an object with numeric keys; normalize to single object
  let record = performanceData;
  if (Array.isArray(performanceData) && performanceData.length > 0) record = performanceData[0];
  // sometimes backend returns an object with numeric keys (e.g. {0: {...}})
  if (record && typeof record === 'object' && !Array.isArray(record) && Object.keys(record).length === 1 && Object.keys(record)[0] === '0') {
    record = record[0];
  }
  record = record || {};

  const academic = {
    gpa: record.gpa ?? record.avg_grade ?? null,
    total_marks_received: record.total_marks_received ?? record.count_marks ?? null,
    total_failed_marks: record.total_failed_marks ?? record.count_failures ?? null,
  };

  const attendance = {
    total_absences: record.total_absences ?? record.count_absences ?? null,
    absence_percentage: record.absence_percentage ?? record.present_percent ?? null,
  };

  const recency = {
    last_activity_date: record.last_activity_date ?? null,
    days_since_last_activity: record.days_since_last_activity ?? record.days_since_last ?? null,
  };

  const segmentation = {
    tier: record.student_status_tier ?? record.status ?? null,
  };

  const fmtPercent = (v) => {
    if (v == null || v === '') return '—';
    const n = Number(typeof v === 'object' && v?.value != null ? v.value : v);
    return Number.isFinite(n) ? `${n.toFixed(1)}%` : String(v);
  };

  const fmtValue = (v) => {
    if (v == null || v === '') return '—';
    if (typeof v === 'object') {
      if ('days' in v && (typeof v.days === 'number' || typeof v.days === 'string')) return v.days;
      if ('value' in v) return v.value;
      try {
        return JSON.stringify(v);
      } catch (e) {
        return String(v);
      }
    }
    return v;
  };

  const fmtDate = (v) => {
    if (!v) return '—';
    try {
      const d = new Date(v);
      if (Number.isNaN(d.getTime())) return String(v);
      return d.toLocaleDateString();
    } catch (e) {
      return String(v);
    }
  };

  return (
    <div>
      <h2 style={{ fontSize: 24, fontWeight: 600, textAlign: 'center' }}>Матриця успішності за навчальний рік</h2>

      <div className="tabs">
      <table className="card" style={{ marginBottom: 12, padding: '15px', width: '60%' }}>
        <thead>
          <tr>
            <th>Показник</th>
            <th>Значення</th>
          </tr>
        </thead>
        <tbody>
          <tr>
            <td>Середній бал (GPA)</td>
            <td><strong>{fmtValue(academic.gpa)}</strong></td>
          </tr>
          <tr>
            <td>Усього оцінок</td>
            <td>{fmtValue(academic.total_marks_received)}</td>
          </tr>
          <tr>
            <td>Погані оцінки</td>
            <td>{fmtValue(academic.total_failed_marks)}</td>
          </tr>
        </tbody>
      </table>

      <table className="card" style={{ marginBottom: 12, padding: '15px', width: '60%' }}>
        <thead>
          <tr>
            <th>Відвідуваність</th>
            <th>Значення</th>
          </tr>
        </thead>
        <tbody>
          <tr>
            <td>К-сть пропусків</td>
            <td>{fmtValue(attendance.total_absences)}</td>
          </tr>
          <tr>
            <td>Відсоток пропусків</td>
            <td>{fmtPercent(attendance.absence_percentage)}</td>
          </tr>
        </tbody>
      </table>

      <table className="card" style={{ marginBottom: 12, padding: '15px', width: '60%' }}>
        <thead>
          <tr>
            <th>Остання активність</th>
            <th>Значення</th>
          </tr>
        </thead>
        <tbody>
          <tr>
            <td>Остання дата активності</td>
            <td>{fmtDate(recency.last_activity_date)}</td>
          </tr>
          <tr>
            <td>Днів від останньої активності</td>
            <td>{fmtValue(recency.days_since_last_activity.hours)} годин {fmtValue(recency.days_since_last_activity.minutes)} хвилин</td>
          </tr>
        </tbody>
      </table>

      <div className="card" style={{ padding: '15px', width: '60%' }}>
        <h3>Сегментація</h3>
        <div style={{ fontSize: 16, fontWeight: 600 }}>{segmentation.tier ?? '—'}</div>
      </div>
    </div>
    </div>
  );
}
