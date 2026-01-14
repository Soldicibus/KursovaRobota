import React, { useState, useMemo } from "react";
import { useStudentMonthlyMarks } from "../../hooks/students/queries/useStudentMonthlyMarks";

export default function MonthlyGradesGrid({ studentId }) {
  const [selectedMonth, setSelectedMonth] = useState(() => {
    const now = new Date();
    return `${now.getFullYear()}-${String(now.getMonth() + 1).padStart(2, '0')}`;
  });

  const { data: marksData, isLoading, error } = useStudentMonthlyMarks(studentId, selectedMonth + "-01");

  const handleMonthChange = (e) => {
    setSelectedMonth(e.target.value);
  };

  const daysInMonth = useMemo(() => {
    const [year, month] = selectedMonth.split('-');
    return new Date(year, month, 0).getDate();
  }, [selectedMonth]);

  const daysArray = useMemo(() => {
    const arr = [];
    for (let i = 1; i <= daysInMonth; i++) {
        arr.push(i);
    }
    return arr;
  }, [daysInMonth]);

  const gridData = useMemo(() => {
    if (!marksData) return {};
    
    // Group by Subject
    // row: subject -> col: day -> value: formatted mark/item
    const grouped = {};
    
    marksData.forEach(item => {
        if (!item.subject_name) return;
        if (!grouped[item.subject_name]) {
            grouped[item.subject_name] = {};
        }
        
        const date = new Date(item.lesson_date);
        const day = date.getDate();
        
        // Handle multiple marks per day? Usually array. For now assume one or overwrite.
        // Let's store an array to be safe
        if (!grouped[item.subject_name][day]) {
            grouped[item.subject_name][day] = [];
        }
        grouped[item.subject_name][day].push(item);
    });
    
    return grouped;
  }, [marksData]);

  const subjects = useMemo(() => Object.keys(gridData).sort(), [gridData]);

  if (!studentId) return null;

  return (
    <div className="card section-card" style={{ marginTop: 20 }}>
      {/* Define custom scrollbar styles locally */}
      <style>{`
        .custom-scrollbar::-webkit-scrollbar {
          height: 10px;
        }
        .custom-scrollbar::-webkit-scrollbar-track {
          background: #f1f1f1;
          border-radius: 5px;
        }
        .custom-scrollbar::-webkit-scrollbar-thumb {
          background: #ccc;
          border-radius: 5px;
        }
        .custom-scrollbar::-webkit-scrollbar-thumb:hover {
          background: #bbb;
        }
      `}</style>

      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: 15 }}>
        <h3 style={{ margin: 0 }}>Місячні оцінки</h3>
        <input 
            type="month" 
            value={selectedMonth} 
            onChange={handleMonthChange}
            style={{ padding: '6px 10px', borderRadius: '6px', border: '1px solid #ccc', outline: 'none', fontSize: '14px' }}
        />
      </div>

      {isLoading && <div>Завантаження...</div>}
      {error && <div style={{color: 'red'}}>Помилка завантаження: {error.message}</div>}

      {!isLoading && !error && (
        <div className="custom-scrollbar" style={{ 
          width: '100%', 
          overflowX: 'auto', 
          border: '1px solid #eee', 
          borderRadius: '8px',
          paddingBottom: '5px' /* space for scrollbar inside border if needed, or just outside */
        }}>
          <table className="monthly-grades-table" style={{ width: '100%', borderCollapse: 'collapse', fontSize: '13px', minWidth: 'max-content' }}>
            <thead>
                <tr style={{ background: '#fcfcfc' }}>
                    <th style={{ textAlign: 'left', padding: '10px 12px', borderBottom: '1px solid #eee', minWidth: '180px', position: 'sticky', left: 0, background: '#fcfcfc', zIndex: 1, borderRight: '1px solid #eee', color: "rgba(0, 0, 0, 0.8)" }}>Предмет</th>
                    {daysArray.map(d => (
                        <th key={d} style={{ padding: '8px', borderBottom: '1px solid #eee', minWidth: '32px', textAlign: 'center', color: '#666', fontWeight: 600 }}>{d}</th>
                    ))}
                </tr>
            </thead>
            <tbody>
                {subjects.length === 0 ? (
                    <tr>
                        <td colSpan={daysInMonth + 1} style={{ padding: '30px', textAlign: 'center', color: '#888' }}>
                            Немає оцінок за цей місяць
                        </td>
                    </tr>
                ) : (
                    subjects.map((subject, idx) => (
                        <tr key={subject} style={{ borderBottom: idx === subjects.length - 1 ? 'none' : '1px solid #f0f0f0' }}>
                            <td style={{ padding: '10px 12px', fontWeight: '600', color: '#333', position: 'sticky', left: 0, background: '#fff', borderRight: '1px solid #eee', zIndex: 1 }}>{subject}</td>
                            {daysArray.map(d => {
                                const items = gridData[subject][d] || [];
                                return (
                                    <td key={d} style={{ padding: '4px', textAlign: 'center', verticalAlign: 'middle', background: '#00000025' }}>
                                        {items.map((item, i) => {
                                            const color = ["П", "Присутній"].includes(item.status) ? "limegreen" :
                                                          ["Н", "Не присутній"].includes(item.status) ? "red" : "inherit";
                                            return (
                                                <div 
                                                    key={i}
                                                    style={{ 
                                                        color: color, 
                                                        fontWeight: 'bold', 
                                                        display: 'inline-block',
                                                        margin: '0 2px',
                                                        fontSize: '14px',
                                                        borderBottom: item.note ? '2px dotted #999' : 'none',
                                                        cursor: item.note ? 'help' : 'default'
                                                    }}
                                                    title={item.note || undefined}
                                                >
                                                    {item.mark != null ? item.mark : (item.status === 'Н' ? 'Н' : (item.status === 'П' ? 'П' : ''))}
                                                </div>
                                            );
                                        })}
                                    </td>
                                );
                            })}
                        </tr>
                    ))
                )}
            </tbody>
          </table>
        </div>
      )}
    </div>
  );
}