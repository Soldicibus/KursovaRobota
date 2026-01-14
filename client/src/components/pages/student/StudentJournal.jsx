import React from "react";
import { useStudentDataMarks7d } from "../../../hooks/studentdata/queries/useStudentDataMarks7d";
import { getCurrentUser } from "../../../utils/auth";
import { useUserData } from "../../../hooks/users";
import MonthlyGradesGrid from "../../common/MonthlyGradesGrid";

function formatDate(value) {
  if (!value) return '—';
  try {
    const d = new Date(value);
    if (Number.isNaN(d.getTime())) return String(value);
    return d.toLocaleString('uk-UA', { year: 'numeric', month: '2-digit', day: '2-digit', hour: d.getHours() ? '2-digit' : undefined, minute: d.getMinutes() ? '2-digit' : undefined });
  } catch (e) {
    return String(value);
  }
}

export default function StudentJournal({ studentId: propStudentId }) {
  if (import.meta.env.DEV) {
    console.log('StudentJournal: propStudentId', propStudentId);
  }
  const currentUser = getCurrentUser();
  const userId = currentUser?.userId || currentUser?.id || currentUser?.sub || null;
  const {data: userData} = useUserData(userId);
  const studentId = propStudentId || userData?.entity_id || userData?.entityId || null;
  const { data: marks7d, isLoading: marksLoading, error } = useStudentDataMarks7d(studentId, { enabled: !!studentId });

  const entries = [];
  if (Array.isArray(marks7d) && marks7d.length > 0) {
    entries.push(...marks7d);
  } else if (marks7d && Array.isArray(marks7d.marks) && marks7d.marks.length > 0) {
    entries.push(...marks7d.marks);
  }

  return (
    <>
    <div className="card journal-card">
      {marksLoading && <div className="loading">Завантаження...</div>}
      {error && <div className="error">Помилка завантаження даних</div>}
      {!marksLoading && entries.length === 0 && <div className="empty-state">Немає записів журналу за останні 7 днів</div>}

      <div className="journal-by-date">
        {(() => {
          const groups = entries.reduce((acc, item) => {
            const raw = item.lesson_date || item.date;
            const key = formatDateShort(raw);
            acc[key] = acc[key] || [];
            acc[key].push(item);
            return acc;
          }, {});
          // sort keys by date desc
          const keys = Object.keys(groups).sort((a, b) => {
            const pa = parseDateFromKey(a);
            const pb = parseDateFromKey(b);
            return pb - pa;
          });

          // Render days as columns with date headers aligned horizontally
          return (
            <>
              {keys.map((k) => {
                const dayEntries = groups[k];
                // group entries by subject name to avoid duplicated subject listings
                const subjectGroups = dayEntries.reduce((acc, item) => {
                  const name = (item.subject || item.discipline || item.subject_name || '—').toString();
                  acc[name] = acc[name] || [];
                  acc[name].push(item);
                  return acc;
                }, {});
                
                const subjectKeys = Object.keys(subjectGroups);
                const mainSubjectName = subjectKeys[0];
                const mainGroup = subjectGroups[mainSubjectName] || [];
                const mainItem = mainGroup[0] || {};
                const otherSubjects = subjectKeys.slice(1).map(s => ({ name: s, items: subjectGroups[s] }));
                
                return (
                  <div key={k} className="journal-column">
                    <div style={{ fontWeight: 700, marginBottom: 8, textAlign: 'center' }}>{k}</div>
                    <div className="journal-subject-card">
                      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
                        <div>
                          <div style={{ fontSize: 16, fontWeight: 600 }}>{mainSubjectName}</div>
                          {mainItem.note && (
                            <div style={{ fontSize: 12, color: "#ffffffff", marginTop: 2, maxWidth: 150 }}>{mainItem.note}</div>
                          )}
                        </div>
                        <div 
                          style={{ 
                            fontSize: 20, 
                            fontWeight: 700,
                            color: ["П", "Присутній"].includes(mainItem.status)
                             ? "limegreen" 
                             : ["Н", "Не присутній"].includes(mainItem.status)
                             ? "red"
                             : "inherit"
                          }}
                        >
                          {(() => {
                            const marks = mainGroup.filter(i => i.mark != null).map(i => Number(i.mark));
                            if (marks.length > 1) {
                              const avg = marks.reduce((a, b) => a + b, 0) / marks.length;
                              return avg % 1 === 0 ? avg : avg.toFixed(1);
                            }
                            return mainItem.mark != null ? mainItem.mark : (mainItem.status || '—');
                          })()}
                        </div>
                      </div>

                      {/* if multiple marks for main subject, list them */}
                      {mainGroup.length > 1 && (
                        <div style={{ marginTop: 8, display: 'flex', gap: 8, flexWrap: 'wrap' }}>
                          {mainGroup.map((mi, ii) => (
                            <div key={ii} style={{ padding: '6px 8px', borderRadius: 4, border: '1px solid #eee', background: '#fafafa', fontSize: 13, color: '#000' }}>
                              <div style={{ fontWeight: 700 }}>{mi.mark != null ? mi.mark : (mi.status || '—')}</div>
                            </div>
                          ))}
                        </div>
                      )}
                    </div>

                    {otherSubjects.length > 0 && (
                      <div className="journal-other-subjects">
                        <div style={{ color: '#666', marginBottom: 6 }}>Інші предмети</div>
                        <div style={{ display: 'grid', gridTemplateColumns: '1fr', gap: 8 }}>
                          {otherSubjects.map((o, idx) => {
                            const item = o.items[0];
                            return (
                              <div key={idx} className="subject-card">
                                <div style={{ fontSize: 14 }}>
                                  <div>{o.name}</div>
                                  <div style={{ color: '#999', fontSize: 12 }}>{o.items.length > 1 ? `${o.items.length} оцінки` : formatTime(item?.lesson_date || item?.date)}</div>
                                  {item?.note && <div style={{ fontSize: 11, color: "#fff", marginTop: 2 }}>{item.note}</div>}
                                </div>
                                <div style={{ 
                                  fontWeight: 700,
                                  color: ["П", "Присутній"].includes(item?.status)
                                   ? "limegreen" 
                                   : ["Н", "Не присутній"].includes(item?.status)
                                   ? "red"
                                   : "inherit"
                                }}>
                                  {item?.mark != null ? item.mark : (item?.status || '—')}
                                </div>
                              </div>
                            );
                          })}
                        </div>
                      </div>
                    )}
                  </div>
                );
              })}
            </>
          );
        })()}
      </div>
    </div>
    <MonthlyGradesGrid studentId={studentId} />
    </>
  );
}

// Helpers
function formatDateShort(value) {
  if (!value) return '—';
  try {
    const d = new Date(value);
    if (Number.isNaN(d.getTime())) return String(value);

    // Format using Europe/Kiev timezone
    const formatter = new Intl.DateTimeFormat('uk-UA', {
      timeZone: 'Europe/Kiev',
      day: '2-digit',
      month: '2-digit',
      year: 'numeric'
    });
    
    // We want specifically dd-mm-yyyy to match the key format expected
    // formatter.format(d) might give "dd.mm.yyyy", so let's use parts
    const parts = formatter.formatToParts(d);
    const day = parts.find(p => p.type === 'day').value;
    const month = parts.find(p => p.type === 'month').value;
    const year = parts.find(p => p.type === 'year').value;
    return `${day}-${month}-${year}`;
  } catch (e) {
    return String(value);
  }
}

function parseDateFromKey(key) {
  // key is dd-mm-yyyy
  const parts = (key || '').split('-');
  if (parts.length === 3) {
    const [dd, mm, yyyy] = parts;
    return new Date(Number(yyyy), Number(mm) - 1, Number(dd));
  }
  const d = new Date(key);
  return Number.isNaN(d.getTime()) ? 0 : d;
}

function formatTime(value) {
  if (!value) return '';
  try {
    const d = new Date(value);
    if (Number.isNaN(d.getTime())) return '';
    return d.toLocaleTimeString('uk-UA', { 
      hour: '2-digit', 
      minute: '2-digit',
      timeZone: 'Europe/Kiev'
    });
  } catch (e) {
    return '';
  }
}
