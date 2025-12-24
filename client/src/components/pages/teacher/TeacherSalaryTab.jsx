import React, { useState } from "react";
import { useTeacherSalaryReport } from "../../../hooks/teachers/queries/useTeacherSalaryReport";

export default function TeacherSalaryTab({ teacherId }) {
  const [dateFrom, setDateFrom] = useState(() => {
    const now = new Date();
    const firstDayPrevMonth = new Date(now.getFullYear(), now.getMonth() - 1, 1);
    return firstDayPrevMonth.toISOString().split("T")[0];
  });

  const [dateTo, setDateTo] = useState(() => {
    const now = new Date();
    const lastDayPrevMonth = new Date(now.getFullYear(), now.getMonth(), 0);
    return lastDayPrevMonth.toISOString().split("T")[0];
  });

console.log("dateFrom:", dateFrom);
   console.log("dateTo:", dateTo);
   console.log("teacherId:", teacherId);

  const { data: salaryReport, isLoading, error } = useTeacherSalaryReport(teacherId, dateFrom, dateTo);

  if (isLoading) return <div>Завантаження...</div>;
  if (error) return <div>Помилка завантаження: {error.message}</div>;
  const filteredReport = Array.isArray(salaryReport) 
    ? salaryReport.filter(item => {
        // Filter by teacherId if item has it
        if (item.teacher_id && String(item.teacher_id) !== String(teacherId)) return false;
        
        // Filter by date if item has a date field (e.g., payment_date, date)
        const itemDate = item.date || item.payment_date;
        if (itemDate) {
            const d = new Date(itemDate);
            const from = new Date(dateFrom);
            const to = new Date(dateTo);
            return d >= from && d <= to;
        }
        return true;
    })
    : [];

  return (
    <div className="card">
      <h2>Зарплата викладача</h2>
      <div style={{ marginBottom: 20, display: "flex", gap: 20 }}>
        <label>
          З:
          <input
            type="date"
            value={dateFrom}
            onChange={(e) => setDateFrom(e.target.value)}
            style={{ marginLeft: 10, padding: 5 }}
          />
        </label>
        <label>
          По:
          <input
            type="date"
            value={dateTo}
            onChange={(e) => setDateTo(e.target.value)}
            style={{ marginLeft: 10, padding: 5 }}
          />
        </label>
      </div>

      {filteredReport.length > 0 ? (
        <table className="data-table">
          <thead>
            <tr>
              <th>Сума</th>
            </tr>
          </thead>
          <tbody>
            {filteredReport.map((item, index) => (
              <tr key={index} style={{ backgroundColor: index % 2 === 0 ? '#f9f9f9' : 'white' }}>
                <td>{item.get_teacher_salary || item.salary || "—"}</td>
              </tr>
            ))}
          </tbody>
        </table>
      ) : (
        <div>Немає даних про зарплату за цей період.</div>
      )}
      
      {import.meta.env.DEV && (
        <details style={{ marginTop: 20 }}>
          <summary>Debug Raw Data</summary>
          <pre>{JSON.stringify(salaryReport, null, 2)}</pre>
        </details>
      )}
    </div>
  );
}
