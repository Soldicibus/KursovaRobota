import React, { useState } from "react";
import useClassAbsent from "../../../hooks/classes/queries/useClassAbsent";

export default function ClassAbsentTab({ className }) {
  const [amount, setAmount] = useState(10);
  const { data: absentReport, isLoading, error } = useClassAbsent(className, amount);

  if (isLoading) return <div>Завантаження...</div>;
  if (error) return <div>Помилка завантаження: {error.message}</div>;

  return (
    <div className="card">
      <h2>Звіт про відсутність учнів</h2>
      <div style={{ marginBottom: 20 }}>
        <label>
          Кількість пропусків більше ніж:
          <input
            type="number"
            value={amount}
            onChange={(e) => setAmount(Number(e.target.value))}
            style={{ marginLeft: 10, padding: 5 }}
          />
        </label>
      </div>
      {absentReport && absentReport.length > 0 ? (
        <table className="data-table">
          <thead>
            <tr>
              <th>Ім'я учня</th>
              <th>Прізвище учня</th>
              <th>Кількість пропусків</th>
            </tr>
          </thead>
          <tbody>
            {absentReport.map((item, index) => (
              <tr key={index} style={{ backgroundColor: index % 2 === 0 ? '#f9f9f9' : '#ffffff' }}>
                <td>{item.student_name}</td>
                <td>{item.student_surname}</td>
                <td>{item.absents}</td>
              </tr>
            ))}
          </tbody>
        </table>
      ) : (
        <div>Немає даних про відсутність для цього класу.</div>
      )}
    </div>
  );
}
