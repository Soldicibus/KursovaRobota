import React from 'react';
import { useStudentRanking } from '../../../hooks/students/queries/useStudentRanking';

function displayName(row) {
  if (!row) return '—';
  // Prefer explicit student_name or common first-name fields, fall back to login/username
  return row.student_name || row.username || row.login || '—';
}

function displaySurname(row) {
  if (!row) return '—';
  return row.student_surname || '—';
}

function displayAvg(row) {
  if (!row) return '—';
  // Prefer avg_mark when available
  const candidates = [row.avg_mark, row.average_score, row.score];
  for (const v of candidates) {
    if (v != null && v !== '') {
      const n = Number(String(v).replace(',', '.'));
      if (!Number.isNaN(n)) return n.toFixed(2);
    }
  }
  return '—';
}

export default function StudentRanking() {
  const { data: ranking, isLoading, error } = useStudentRanking();

  if (isLoading) return <div>Завантаження рейтингу...</div>;
  if (error) return <div>Помилка: {error.message || 'Не вдалося завантажити рейтинг'}</div>;

  // Debug: log the ranking shape in dev
  if (import.meta?.env?.DEV) {
    console.log('StudentRanking: raw ranking value', ranking);
  }

  let rows = [];
  if (Array.isArray(ranking)) {
    rows = ranking;
  } else if (ranking && Array.isArray(ranking.students)) {
    rows = ranking.students;
  } else if (ranking && ranking.data && Array.isArray(ranking.data.students)) {
    rows = ranking.data.students;
  } else if (ranking && Array.isArray(ranking.data)) {
    rows = ranking.data;
  }

  if (rows.length > 0 && Array.isArray(rows[0])) {
    rows = rows.map(r => ({ id: r[0], name: r[1], class: r[2], avg: r[3], rank: r[4] }));
  }

  if (!rows || rows.length === 0) return <div>Рейтинг наразі порожній</div>;

  // sort by numeric average descending
  function getAvgNumeric(row) {
    const candidates = [row.avg_mark];
    for (const v of candidates) {
      if (v != null && v !== '') {
        const n = Number(String(v).replace(',', '.'));
        if (!Number.isNaN(n)) return n;
      }
    }
    return -Infinity;
  }

  const sorted = rows.slice().sort((a, b) => getAvgNumeric(b) - getAvgNumeric(a));

  return (
    <div className="card">
      <h3>Рейтинг учнів</h3>
      <table className="table">
        <thead>
          <tr>
            <th>Місце</th>
            <th>Ім'я</th>
            <th>Прізвище</th>
            <th>Клас</th>
            <th>Середній</th>
          </tr>
        </thead>
        <tbody>
          {sorted.map((r, idx) => (
            <tr key={r.student_id}>
              <td>{idx + 1}</td>
              <td>{displayName(r)}</td>
              <td>{displaySurname(r)}</td>
              <td>{r.student_class || '—'}</td>
              <td>{displayAvg(r)}</td>
            </tr>
          ))}
        </tbody>
      </table>
      {sorted.length > 0 && (displayName(sorted[0]) === '—' && displayAvg(sorted[0]) === '—') && (
        <pre style={{ fontSize: 12, marginTop: 8 }}>{JSON.stringify(sorted[0], null, 2)}</pre>
      )}
    </div>
  );
}
