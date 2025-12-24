import React from 'react';
import { useStudentAttendanceReport } from '../../../hooks/students/queries/useStudentAttendance';
import { useUserData } from '../../../hooks/users/queries/useUserData';
import { useStudent } from '../../../hooks/students/queries/useStudent';
import { getCurrentUser } from '../../../utils/auth';

export default function StudentGradesAndAbsences({ enabled = true, studentId: propStudentId }) {
  const currentUser = getCurrentUser();
  const userId = currentUser?.userId || currentUser?.id || currentUser?.sub || null;
  const { data: userRes, isLoading: userDataLoading } = useUserData(userId, { enabled: !!userId });
  const userData = userRes?.userData ?? userRes?.user ?? userRes ?? null;


  let resolvedStudentId = propStudentId || userData?.entity_id || userData?.entityId || null;
  const {data: student} = useStudent(resolvedStudentId, { enabled: !!resolvedStudentId });
  if (!resolvedStudentId && userData) {
    resolvedStudentId = userData?.student_id || userData?.studentId || userData?.entity_id || userData?.entityId || null;
  }
  else if (!resolvedStudentId && !userData && student) {
    resolvedStudentId = student?.id || student?.entity_id || student?.entityId || null;
  }
  if (import.meta?.env?.DEV) {
    console.log('student grades: resolvedStudentId', { propStudentId, userId, resolvedStudentId, userData });
  }

  const { data: attendanceReport = [], isLoading: attendanceLoading } = useStudentAttendanceReport(
    resolvedStudentId,
    { enabled: enabled && !!resolvedStudentId }
  );
  const isLoading = userDataLoading || attendanceLoading;

  if (isLoading) return <div>Завантаження відвідуваності...</div>;
  if (!resolvedStudentId) return <div>Не знайдено ID учня</div>;
  const attendanceTotals = Array.isArray(attendanceReport) && attendanceReport.length > 0 ? attendanceReport[0] : null;
  const presentCount = attendanceTotals
    ? (attendanceTotals.present ?? attendanceTotals.present_count ?? attendanceTotals.presentCount ?? 0)
    : null;
  const absentCount = attendanceTotals
    ? (attendanceTotals.absent ?? attendanceTotals.absent_count ?? attendanceTotals.absentCount ?? 0)
    : null;
  const presentPercent = attendanceTotals
    ? (attendanceTotals.present_percent ?? attendanceTotals.presentPercent ?? attendanceTotals.percent ?? null)
    : null;
  
  // Attendance summary table component and status message
  const AttendanceSummaryTable = () => (
    attendanceTotals ? (
      <div>
        <table className="card" style={{ marginBottom: 12, padding: '15px', alignContent: 'center', position: 'relative' }}>
          <thead>
            <tr>
              <th>Присутній (П)</th>
              <th>Не присутній (Н)</th>
              <th>Присутність</th>
            </tr>
          </thead>
          <tbody>
            <tr>
              <td><strong>{presentCount ?? '—'}</strong></td>
              <td><strong>{absentCount ?? '—'}</strong></td>
              <td><strong>{presentPercent != null ? `${Number(presentPercent).toFixed(2)}%` : '—'}</strong></td>
            </tr>
          </tbody>
        </table>
        {presentPercent != null && (
          <div className="attendance-status">
            {Number(presentPercent) >= 75 ? (
              <span className="attendance-ok">Норма — відвідуваність відповідає вимогам</span>
            ) : (
              <span className="attendance-bad">Потрібно відвідувати більше уроків</span>
            )}
          </div>
        )}
      </div>
    ) : null
  );

  return attendanceTotals ? <AttendanceSummaryTable /> : <div>Немає даних про відвідуваність</div>;
}
