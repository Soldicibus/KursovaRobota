import React, { useState, useEffect } from "react";
import { useTeacherSalaryReport } from "../../../hooks/teachers/queries/useTeacherSalaryReport";
import ErrorModal from "../../common/ErrorModal";

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

  const [debouncedDateFrom, setDebouncedDateFrom] = useState(dateFrom);
  const [debouncedDateTo, setDebouncedDateTo] = useState(dateTo);

  useEffect(() => {
    const handler = setTimeout(() => {
      setDebouncedDateFrom(dateFrom);
    }, 1500);
    return () => clearTimeout(handler);
  }, [dateFrom]);

  useEffect(() => {
    const handler = setTimeout(() => {
      setDebouncedDateTo(dateTo);
    }, 1500);
    return () => clearTimeout(handler);
  }, [dateTo]);

console.log("dateFrom:", debouncedDateFrom);
   console.log("dateTo:", debouncedDateTo);
   console.log("teacherId:", teacherId);

  const isValidDate = (dStr) => {
    if (!dStr) return false;
    const d = new Date(dStr);
    return !isNaN(d.getTime());
  };

  const isInvalidRange = debouncedDateFrom && debouncedDateTo && new Date(debouncedDateFrom) > new Date(debouncedDateTo);
  const [rangeError, setRangeError] = useState(null);

  useEffect(() => {
    if (isInvalidRange) {
      setRangeError("What do you think this is? Fucking fairyland?");
    } else {
      setRangeError(null);
    }
  }, [isInvalidRange]);

  const { data: salaryReport, isLoading, error } = useTeacherSalaryReport(
    teacherId,
    debouncedDateFrom,
    debouncedDateTo,
    { enabled: isValidDate(debouncedDateFrom) && isValidDate(debouncedDateTo) && !isInvalidRange }
  );

  if (isLoading) return <div>Завантаження...</div>;
  if (error) return <div>Помилка завантаження: {error.message}</div>;
  const filteredReport = Array.isArray(salaryReport) 
    ? salaryReport.filter(item => {
        // Filter by teacherId if item has it
        if (item.teacher_id && String(item.teacher_id) !== String(teacherId)) return false;
        
        if (debouncedDateFrom || debouncedDateTo) {
          const itemDate = item.date || item.payment_date;
          if (itemDate) {
            const d = new Date(itemDate);

            let from = debouncedDateFrom ? new Date(debouncedDateFrom) : new Date("1900-01-01");
            if (isNaN(from.getTime())) from = new Date(); // Fallback to current date if format is wrong

            let to = debouncedDateTo ? new Date(debouncedDateTo) : new Date("2100-01-01");
            if (isNaN(to.getTime())) to = new Date(); // Fallback to current date if format is wrong

            return d >= from && d <= to;
          }
        }
        return true;
    })
    : [];

  return (
    <div className="card">
      <ErrorModal error={rangeError} onClose={() => setRangeError(null)} />
      <h2>Зарплата викладача</h2>
      <div style={{ marginBottom: 20, display: "flex", gap: 20 }}>
        <label>
          З:
          <input
            type="date"
            value={dateFrom}
            onChange={(e) => {
              const val = e.target.value;
              if (val === null || val === undefined) return;
              // If it's just whitespace, treat as empty
              if (val.trim() === "") {
                setDateFrom("");
              } else {
                setDateFrom(val);
              }
            }}
            style={{ marginLeft: 10, padding: 5 }}
          />
        </label>
        <label>
          По:
          <input
            type="date"
            value={dateTo}
            onChange={(e) => {
              const val = e.target.value;
              if (val === null || val === undefined) return;
              if (val.trim() === "") {
                setDateTo("");
              } else {
                setDateTo(val);
              }
            }}
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