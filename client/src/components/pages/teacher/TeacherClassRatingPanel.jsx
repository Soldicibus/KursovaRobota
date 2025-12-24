import React, { useMemo } from "react";
import { useClassRating } from "../../../hooks/classes/queries/useClassRating";

export default function TeacherClassRatingPanel() {
  const { data, isLoading } = useClassRating();

  const rows = useMemo(() => {
    if (isLoading) return [];
    if (Array.isArray(data)) return data;
    return data?.rows ?? data?.report ?? [];
  }, [data, isLoading]);

  return (
    <section className="card">
      <h2>Рейтинг класів</h2>

      {rows.length === 0 ? (
        <p>Немає даних.</p>
      ) : (
        <div style={{ overflowX: "auto" }}>
          <table style={{ width: "100%", borderCollapse: "collapse" }}>
            <thead>
              <tr>
                <th style={{ textAlign: "left", padding: "6px 8px" }}>Клас</th>
                <th style={{ textAlign: "left", padding: "6px 8px" }}>Учнів</th>
                <th style={{ textAlign: "left", padding: "6px 8px" }}>
                  Середня оцінка
                </th>
                <th style={{ textAlign: "left", padding: "6px 8px" }}>Місце</th>
              </tr>
            </thead>
            <tbody>
              {rows.map((r, idx) => (
                <tr key={r.student_class || idx}>
                  <td style={{ padding: "6px 8px" }}>{r.student_class}</td>
                  <td style={{ padding: "6px 8px" }}>{r.students_count}</td>
                  <td style={{ padding: "6px 8px" }}>{r.avg_mark}</td>
                  <td style={{ padding: "6px 8px" }}>{r.rank_position}</td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      )}
    </section>
  );
}
