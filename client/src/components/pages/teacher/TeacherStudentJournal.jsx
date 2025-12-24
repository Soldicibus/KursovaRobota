import React, { useMemo, useState } from "react";
import { useStudentDataMarks7d } from "../../../hooks/studentdata/queries/useStudentDataMarks7d";
import { useCreateStudentData } from "../../../hooks/studentdata/mutations/useCreateStudentData";
import { useUpdateStudentData } from "../../../hooks/studentdata/mutations/useUpdateStudentData";
import { useDeleteStudentData } from "../../../hooks/studentdata/mutations/useDeleteStudentData";
import { useCreateLesson } from "../../../hooks/lessons/mutations/useCreateLesson";
import { useLessonName } from "../../../hooks/lessons/queries/useLessonName";
import { useSubjects } from "../../../hooks/subjects/queries/useSubjects";
import { useMaterials } from "../../../hooks/materials/queries/useMaterials";
import { useUserData } from "../../../hooks/users/queries/useUserData";
import { getCurrentUser } from "../../../utils/auth";
import { useStudent } from "../../../hooks/students/queries/useStudent";
import { useTimetableByStudent } from "../../../hooks/timetables/queries/useTimetableByStudent";

function formatDateShort(value) {
  if (!value) return "—";
  try {
    const d = new Date(value);
    if (Number.isNaN(d.getTime())) return String(value);
    const dd = String(d.getDate()).padStart(2, "0");
    const mm = String(d.getMonth() + 1).padStart(2, "0");
    const yyyy = d.getFullYear();
    return `${dd}-${mm}-${yyyy}`;
  } catch {
    return String(value);
  }
}

function parseDateFromKey(key) {
  const parts = (key || "").split("-");
  if (parts.length === 3) {
    const [dd, mm, yyyy] = parts;
    const d = new Date(Number(yyyy), Number(mm) - 1, Number(dd));
    return Number.isNaN(d.getTime()) ? 0 : d.getTime();
  }
  const d = new Date(key);
  return Number.isNaN(d.getTime()) ? 0 : d.getTime();
}

function formatTime(value) {
  if (!value) return "";
  try {
    const d = new Date(value);
    if (Number.isNaN(d.getTime())) return "";
    return d.toLocaleTimeString("uk-UA", { hour: "2-digit", minute: "2-digit" });
  } catch {
    return "";
  }
}
export default function TeacherStudentJournal({ studentId, studentName, onBack }) {
  const {
    data: marks7d,
    isLoading: marksLoading,
    error,
    isError,
  } = useStudentDataMarks7d(studentId);

  const createStudentData = useCreateStudentData();
  const updateStudentData = useUpdateStudentData();
  const deleteStudentData = useDeleteStudentData();
  const { data: student } = useStudent(studentId);
  const { data: timetable } = useTimetableByStudent(studentId);
  console.log("timetable:", timetable);
  const createLesson = useCreateLesson();

  const { data: subjects } = useSubjects();
  const { data: materials } = useMaterials();

  const currentUser = getCurrentUser();
  const userId = currentUser?.userId || currentUser?.id || currentUser?.sub || null;
  const { data: userRes } = useUserData(userId);
  const userData = userRes?.userData ?? userRes?.user ?? userRes ?? null;
  const teacherId = userData?.teacher_id || userData?.teacherId || userData?.entity_id || null;

  const [modal, setModal] = useState(null);
  const [form, setForm] = useState({
    mark: "",
    status: "",
    note: "",
    lessonMode: "existing", // existing | new
    lessonNameSearch: "",
    newLessonName: "",
    newLessonSubject: "",
    newLessonMaterial: "",
    newLessonDate: "",
  });

  const [lessonSearch, setLessonSearch] = useState("");
  const { data: searchedLesson } = useLessonName(lessonSearch);

  const entries = useMemo(() => {
    const out = [];
    if (Array.isArray(marks7d) && marks7d.length > 0) out.push(...marks7d);
    else if (marks7d && Array.isArray(marks7d.marks) && marks7d.marks.length > 0) out.push(...marks7d.marks);
    return out;
  }, [marks7d]);

  const openActions = (entry) => {
    if (!entry) return;
    setModal({ type: "actions", entry });
  };

  const onCreateNew = () => {
    setForm({
      mark: "",
      status: "",
      note: "",
      lessonMode: "existing",
      lessonNameSearch: "",
      newLessonName: "",
      newLessonSubject: "",
      newLessonMaterial: "",
      newLessonDate: new Date().toISOString().slice(0, 16),
    });
    setLessonSearch("");
    setModal({ type: "create" });
  };

  const onEdit = (entry) => {
    setForm({
      mark: entry.mark != null ? String(entry.mark) : "",
      status: entry.status || "",
      note: entry.note || "",
      // Edit mode doesn't support changing lesson for now
      lessonMode: "existing",
      lessonNameSearch: "",
      newLessonName: "",
      newLessonSubject: "",
      newLessonMaterial: "",
      newLessonDate: "",
    });
    setModal({ type: "edit", entry });
  };

  const closeModal = () => setModal(null);

  const handleCreateSubmit = async () => {
    try {
      let lessonId = null;

      if (form.lessonMode === "new") {
        const newLessonRes = await createLesson.mutateAsync({
          name: form.newLessonName,
          className: student?.class_name || student?.className || student?.student_class || "",
          subjectId: form.newLessonSubject,
          materialId: form.newLessonMaterial,
          teacherId: teacherId,
          date: form.newLessonDate || new Date().toISOString(),
        });
        const resData = newLessonRes?.data || newLessonRes;
        lessonId = resData?.lessonId || resData?.id || resData?.insertId;
      } else {
        if (!searchedLesson) {
          alert("Lesson not found! Please search and select a valid lesson.");
          return;
        }
        lessonId = searchedLesson.id || searchedLesson.lesson_id;
      }

      if (!lessonId) {
        alert("Could not determine Lesson ID.");
        return;
      }

      // journalId is usually tied to the class/subject. 
      // The prompt says "journal_id (auto get from marks7d)".
      // marks7d is an array of entries. We can try to get journal_id from the first entry if available.
      // Or maybe the backend handles it?
      // The API requires journalId.
      // The 7d marks hook returns the journal id as well.
      let journalId = marks7d?.journalId || marks7d?.journal_id || entries[0]?.journal_id || entries[0]?.journalId;

      if (!journalId) {
        // Fallback to timetable ID if marks7d is empty/null
        // The prompt says "timetable_id = journal_id for the most part"
        if (Array.isArray(timetable) && timetable.length > 0) {
           journalId = timetable[0]?.get_timetable_id_by_student_id;
        } else {
           journalId = timetable?.get_timetable_id_by_student_id || timetable?.id || timetable?.timetable_id || timetable?.journal_id;
        }
      }

      await createStudentData.mutateAsync({
        journalId: journalId || null,
        studentId: studentId,
        lesson: lessonId,
        mark: form.mark ? Number(form.mark) : null,
        status: form.status || null,
        note: form.note,
      });
      closeModal();
    } catch (err) {
      console.error(err);
      alert("Error creating mark: " + err.message);
    }
  };

  const handleUpdateSubmit = async () => {
    try {
      const entry = modal.entry;
      const dataId = entry.id || entry.data_id || entry.student_data_id;
      if (!dataId) {
        alert("Error: Data ID is missing.");
        return;
      }

      // For update, we keep existing lesson and journal
      const journalId = entry.journal_id || entry.journalId;
      const lessonId = entry.lesson_id || entry.lessonId;

      await updateStudentData.mutateAsync({
        id: dataId,
        journalId: journalId,
        studentId: studentId,
        lesson: lessonId,
        mark: form.mark ? Number(form.mark) : null,
        status: form.status || null,
        note: form.note,
      });
      closeModal();
    } catch (err) {
      console.error(err);
      alert("Error updating mark: " + err.message);
    }
  };

  const handleDeleteSubmit = async () => {
    try {
      const entry = modal.entry;
      const dataId = entry.id || entry.data_id || entry.student_data_id;
      if (!dataId) return;
      await deleteStudentData.mutateAsync(dataId);
      closeModal();
    } catch (err) {
      console.error(err);
      alert("Error deleting mark: " + err.message);
    }
  };

  const entryTitle = (entry) => {
    const subj = entry?.subject || entry?.discipline || entry?.subject_name;
    const when = entry?.lesson_date || entry?.date;
    const t = formatTime(when);
    const val = entry?.mark != null ? entry.mark : entry?.status;
    const left = subj ? String(subj) : "Оцінка";
    const right = [t, val != null ? String(val) : "—"].filter(Boolean).join(" • ");
    return [left, right].filter(Boolean).join(" — ");
  };

  const renderModal = () => {
    if (!modal) return null;

    const overlayStyle = {
      position: "fixed",
      inset: 0,
      background: "rgba(0,0,0,0.45)",
      color: "#000",
      display: "flex",
      alignItems: "center",
      justifyContent: "center",
      zIndex: 1000,
      padding: 16,
    };

    const boxStyle = {
      width: "min(520px, 100%)",
      background: "#fff",
      borderRadius: 12,
      boxShadow: "0 12px 40px rgba(0,0,0,0.25)",
      padding: 16,
    };

    const headerStyle = {
      display: "flex",
      justifyContent: "space-between",
      alignItems: "center",
      gap: 12,
      marginBottom: 10,
    };

    const titleStyle = { fontWeight: 800, fontSize: 16 };
    const subStyle = { opacity: 0.75, fontSize: 13, marginTop: 2 };

    const buttonRowStyle = {
      display: "flex",
      gap: 10,
      justifyContent: "flex-end",
      flexWrap: "wrap",
      marginTop: 14,
    };

    const btnStyle = {
      padding: "8px 12px",
      borderRadius: 10,
      border: "1px solid #e6e6e6",
      cursor: "pointer",
      fontWeight: 700,
    };

    const btnDangerStyle = {
      ...btnStyle,
      border: "1px solid #ffd1d1",
      background: "#fff5f5",
      color: "#b40000",
    };

    const btnPrimaryStyle = {
      ...btnStyle,
      border: "1px solid #d5e7ff",
      background: "#f0f7ff",
      color: "#124a9e",
    };

    const stop = (e) => e.stopPropagation();

    if (modal.type === "actions") {
      const entry = modal.entry;
      return (
        <div style={overlayStyle} onClick={closeModal} role="dialog" aria-modal="true">
          <div style={boxStyle} onClick={stop}>
            <div style={headerStyle}>
              <div>
                <div style={titleStyle}>Оберіть дію</div>
                <div style={subStyle}>{entryTitle(entry)}</div>
              </div>
              <button type="button" onClick={closeModal} style={btnStyle}>
                ✕
              </button>
            </div>

            <div style={buttonRowStyle}>
              <button
                type="button"
                style={btnPrimaryStyle}
                onClick={() => onEdit(entry)}
              >
                Редагувати
              </button>
              <button
                type="button"
                style={btnDangerStyle}
                onClick={() => setModal({ type: "confirmDelete", entry })}
              >
                Видалити
              </button>
            </div>
          </div>
        </div>
      );
    }

    if (modal.type === "confirmDelete") {
      const entry = modal.entry;
      return (
        <div style={overlayStyle} onClick={closeModal} role="dialog" aria-modal="true">
          <div style={boxStyle} onClick={stop}>
            <div style={headerStyle}>
              <div>
                <div style={titleStyle}>Ви впевнені?</div>
                <div style={subStyle}>{entryTitle(entry)}</div>
              </div>
              <button type="button" onClick={closeModal} style={btnStyle}>
                ✕
              </button>
            </div>

            <div style={{ opacity: 0.9 }}>
              Цю дію не можна буде скасувати.
            </div>

            <div style={buttonRowStyle}>
              <button type="button" style={btnStyle} onClick={() => setModal({ type: "actions", entry })}>
                Назад
              </button>
              <button
                type="button"
                style={btnDangerStyle}
                onClick={handleDeleteSubmit}
              >
                Так, видалити
              </button>
            </div>
          </div>
        </div>
      );
    }

    if (modal.type === "edit") {
      const entry = modal.entry;
      return (
        <div style={overlayStyle} onClick={closeModal} role="dialog" aria-modal="true">
          <div style={boxStyle} onClick={stop}>
            <div style={headerStyle}>
              <div>
                <div style={titleStyle}>Редагування оцінки (шаблон)</div>
                <div style={subStyle}>{entryTitle(entry)}</div>
              </div>
              <button type="button" onClick={closeModal} style={btnStyle}>
                ✕
              </button>
            </div>

            <div style={{ display: "grid", gap: 10 }}>
              <label style={{ display: "grid", gap: 6 }}>
                <div style={{ fontWeight: 700 }}>Оцінка</div>
                <input
                  placeholder="Напр., 12"
                  value={form.mark}
                  onChange={e => setForm({...form, mark: e.target.value})}
                  style={{ padding: 10, borderRadius: 10, border: "1px solid #e6e6e6" }}
                />
              </label>
              <label style={{ display: "grid", gap: 6 }}>
                <div style={{ fontWeight: 700 }}>Статус</div>
                <select
                  value={form.status}
                  onChange={e => setForm({...form, status: e.target.value})}
                  style={{ padding: 10, borderRadius: 10, border: "1px solid #e6e6e6" }}
                >
                  <option value="">-- Оберіть статус --</option>
                  <option value="Н">Н</option>
                  <option value="П">П</option>
                  <option value="Не присутній">Не присутній</option>
                  <option value="Присутній">Присутній</option>
                </select>
              </label>
              <label style={{ display: "grid", gap: 6 }}>
                <div style={{ fontWeight: 700 }}>Коментар</div>
                <textarea
                  rows={3}
                  placeholder="Гарна робота!"
                  value={form.note}
                  onChange={e => setForm({...form, note: e.target.value})}
                  style={{ padding: 10, borderRadius: 10, border: "1px solid #e6e6e6" }}
                />
              </label>
            </div>

            <div style={buttonRowStyle}>
              <button type="button" style={btnStyle} onClick={() => setModal({ type: "actions", entry })}>
                Назад
              </button>
              <button
                type="button"
                style={btnPrimaryStyle}
                onClick={handleUpdateSubmit}
              >
                Зберегти
              </button>
            </div>
          </div>
        </div>
      );
    }

    if (modal.type === "create") {
      return (
        <div style={overlayStyle} role="dialog" aria-modal="true">
          <div style={boxStyle} onClick={stop}>
            <div style={headerStyle}>
              <div>
                <div style={titleStyle}>Додати оцінку (шаблон)</div>
                <div style={subStyle}>Новий запис у журнал</div>
              </div>
              <button type="button" onClick={closeModal} style={btnStyle}>
                ✕
              </button>
            </div>

            <div style={{ display: "grid", gap: 10, maxHeight: "70vh", overflowY: "auto" }}>
              <label style={{ display: "grid", gap: 6 }}>
                <div style={{ fontWeight: 700 }}>Оцінка</div>
                <input
                  placeholder="Напр., 12"
                  value={form.mark}
                  onChange={e => setForm({...form, mark: e.target.value})}
                  style={{ padding: 10, borderRadius: 10, border: "1px solid #e6e6e6" }}
                />
              </label>
              <label style={{ display: "grid", gap: 6 }}>
                <div style={{ fontWeight: 700 }}>Статус</div>
                <select
                  value={form.status}
                  onChange={e => setForm({...form, status: e.target.value})}
                  style={{ padding: 10, borderRadius: 10, border: "1px solid #e6e6e6" }}
                >
                  <option value="">-- Оберіть статус --</option>
                  <option value="Н">Н</option>
                  <option value="П">П</option>
                  <option value="Не присутній">Не присутній</option>
                  <option value="Присутній">Присутній</option>
                </select>
              </label>
              <label style={{ display: "grid", gap: 6 }}>
                <div style={{ fontWeight: 700 }}>Коментар</div>
                <textarea
                  rows={3}
                  placeholder="Гарна робота!"
                  value={form.note}
                  onChange={e => setForm({...form, note: e.target.value})}
                  style={{ padding: 10, borderRadius: 10, border: "1px solid #e6e6e6" }}
                />
              </label>

              {/* Lesson Selection */}
              <div style={{ border: "1px solid #eee", padding: 10, borderRadius: 10 }}>
                <div style={{ fontWeight: 700, marginBottom: 8 }}>Урок</div>
                <div style={{ display: "flex", gap: 12, marginBottom: 10 }}>
                  <label style={{ display: "flex", gap: 6, alignItems: "center", cursor: "pointer" }}>
                    <input 
                      type="radio" 
                      name="lessonMode" 
                      checked={form.lessonMode === "existing"} 
                      onChange={() => setForm({...form, lessonMode: "existing"})}
                    />
                    Існуючий урок
                  </label>
                  <label style={{ display: "flex", gap: 6, alignItems: "center", cursor: "pointer" }}>
                    <input 
                      type="radio" 
                      name="lessonMode" 
                      checked={form.lessonMode === "new"} 
                      onChange={() => setForm({...form, lessonMode: "new"})}
                    />
                    Створити новий
                  </label>
                </div>

                {form.lessonMode === "existing" ? (
                  <label style={{ display: "grid", gap: 6 }}>
                    <div style={{ fontSize: 13, opacity: 0.8 }}>Назва уроку (пошук)</div>
                    <input 
                      value={form.lessonNameSearch}
                      onChange={e => {
                        setForm({...form, lessonNameSearch: e.target.value});
                        setLessonSearch(e.target.value);
                      }}
                      placeholder="Введіть назву уроку..." 
                      style={{ padding: 10, borderRadius: 10, border: "1px solid #e6e6e6" }} 
                    />
                    {lessonSearch && (
                      <div style={{ fontSize: 12, color: searchedLesson ? "green" : "red" }}>
                        {searchedLesson ? `Знайдено ID: ${searchedLesson.id || searchedLesson.lesson_id}` : "Не знайдено"}
                      </div>
                    )}
                  </label>
                ) : (
                  <div style={{ display: "grid", gap: 8 }}>
                    <label style={{ display: "grid", gap: 4 }}>
                      <div style={{ fontSize: 13 }}>Назва нового уроку</div>
                      <input 
                        value={form.newLessonName}
                        onChange={e => setForm({...form, newLessonName: e.target.value})}
                        placeholder="Напр., Вступ до алгебри"
                        style={{ padding: 8, borderRadius: 8, border: "1px solid #e6e6e6" }}
                      />
                    </label>
                    <label style={{ display: "grid", gap: 4 }}>
                      <div style={{ fontSize: 13 }}>Предмет</div>
                      <select 
                        value={form.newLessonSubject}
                        onChange={e => setForm({...form, newLessonSubject: e.target.value})}
                        style={{ padding: 8, borderRadius: 8, border: "1px solid #e6e6e6" }}
                      >
                        <option value="">-- Оберіть предмет --</option>
                        {Array.isArray(subjects) && subjects.map(s => (
                          <option key={s.id || s.subject_id} value={s.id || s.subject_id}>
                            {s.subject_name || s.name}
                          </option>
                        ))}
                      </select>
                    </label>
                    <label style={{ display: "grid", gap: 4 }}>
                      <div style={{ fontSize: 13 }}>Матеріал</div>
                      <select 
                        value={form.newLessonMaterial}
                        onChange={e => setForm({...form, newLessonMaterial: e.target.value})}
                        style={{ padding: 8, borderRadius: 8, border: "1px solid #e6e6e6" }}
                      >
                        <option value="">-- Оберіть матеріал --</option>
                        {Array.isArray(materials) && materials.map(m => (
                          <option key={m.id || m.material_id} value={m.id || m.material_id}>
                            {m.material_name || m.name}
                          </option>
                        ))}
                      </select>
                    </label>
                    <label style={{ display: "grid", gap: 4 }}>
                      <div style={{ fontSize: 13 }}>Дата проведення</div>
                      <input 
                        type="datetime-local"
                        value={form.newLessonDate}
                        onChange={e => setForm({...form, newLessonDate: e.target.value})}
                        style={{ padding: 8, borderRadius: 8, border: "1px solid #e6e6e6" }}
                      />
                    </label>
                  </div>
                )}
              </div>
            </div>

            <div style={buttonRowStyle}>
              <button type="button" style={btnStyle} onClick={closeModal}>
                Скасувати
              </button>
              <button
                type="button"
                style={btnPrimaryStyle}
                onClick={handleCreateSubmit}
              >
                Створити
              </button>
            </div>
          </div>
        </div>
      );
    }

    return null;
  };

  return (
    <div className="card journal-card">
      {renderModal()}
      <div style={{ display: "flex", alignItems: "center", justifyContent: "space-between", gap: 12 }}>
        <div style={{ display: "flex", alignItems: "baseline", gap: 10, flexWrap: "wrap" }}>
          <h2 style={{ margin: 0 }}>Журнал учня</h2>
          <div style={{ opacity: 0.8 }}>{studentName ? studentName : studentId ? `ID: ${studentId}` : ""}</div>
        </div>

        <div style={{ display: "flex", gap: 8 }}>
          <button type="button" onClick={onCreateNew}>
            + Додати
          </button>
          <button type="button" onClick={onBack}>
            Назад
          </button>
        </div>
      </div>

      {marksLoading && <div className="loading">Завантаження...</div>}
      {isError && <div className="error">Помилка завантаження даних{error?.message ? `: ${error.message}` : ""}</div>}
      {!marksLoading && !isError && entries.length === 0 && (
        <div className="empty-state">Немає записів журналу за останні 7 днів</div>
      )}

      <div className="journal-by-date" style={{ marginTop: 12 }}>
        {(() => {
          const groups = entries.reduce((acc, item) => {
            const raw = item.lesson_date || item.date;
            const key = formatDateShort(raw);
            acc[key] = acc[key] || [];
            acc[key].push(item);
            return acc;
          }, {});

          const keys = Object.keys(groups).sort((a, b) => parseDateFromKey(b) - parseDateFromKey(a));

          return (
            <>
              {keys.map((k) => {
                const dayEntries = groups[k];
                const subjectGroups = dayEntries.reduce((acc, item) => {
                  const name = (item.subject || item.discipline || item.subject_name || "—").toString();
                  acc[name] = acc[name] || [];
                  acc[name].push(item);
                  return acc;
                }, {});

                const subjectKeys = Object.keys(subjectGroups);
                const mainSubjectName = subjectKeys[0];
                const mainGroup = subjectGroups[mainSubjectName] || [];
                const mainItem = mainGroup[0] || {};
                const otherSubjects = subjectKeys
                  .slice(1)
                  .map((s) => ({ name: s, items: subjectGroups[s] }));

                return (
                  <div key={k} className="journal-column">
                    <div style={{ fontWeight: 700, marginBottom: 8, textAlign: "center" }}>{k}</div>

                    <div
                      className="journal-subject-card"
                      role="button"
                      tabIndex={0}
                      title="Натисніть, щоб редагувати/видалити (шаблон)"
                      onClick={() => openActions(mainItem)}
                      onKeyDown={(e) => {
                        if (e.key === "Enter" || e.key === " ") openActions(mainItem);
                      }}
                      style={{ cursor: "pointer" }}
                    >
                      <div
                        style={{
                          display: "flex",
                          justifyContent: "space-between",
                          alignItems: "center",
                          gap: 10,
                        }}
                      >
                        <div style={{ fontSize: 16, fontWeight: 600 }}>{mainSubjectName}</div>

                        <div style={{
                          fontSize: 18,
                          color: "#222",
                          fontWeight: 800,
                          padding: "6px 10px",
                          borderRadius: 8,
                          border: "1px solid #eee",
                          background: "#f9f9f9"
                        }}>
                          {(() => {
                            const marks = mainGroup.filter(i => i.mark != null).map(i => Number(i.mark));
                            if (marks.length > 1) {
                              const avg = marks.reduce((a, b) => a + b, 0) / marks.length;
                              return avg % 1 === 0 ? avg : avg.toFixed(1);
                            }
                            return mainItem.mark != null ? mainItem.mark : (mainItem.status || "—");
                          })()}
                        </div>
                      </div>

                      {mainGroup.length > 1 && (
                        <div style={{ marginTop: 8, display: "flex", gap: 8, flexWrap: "wrap" }}>
                          {mainGroup.map((mi, ii) => (
                            <button
                              type="button"
                              key={ii}
                              onClick={(e) => {
                                e.stopPropagation();
                                openActions(mi);
                              }}
                              title="Натисніть, щоб редагувати/видалити (шаблон)"
                              style={{
                                padding: "6px 8px",
                                borderRadius: 6,
                                border: "1px solid #eee",
                                background: "#fafafa",
                                fontSize: 13,
                                cursor: "pointer",
                                textAlign: "left",
                              }}
                            >
                              <div style={{ fontWeight: 800, color: "#000" }}>{mi.mark != null ? mi.mark : mi.status || "—"}</div>
                            </button>
                          ))}
                        </div>
                      )}
                    </div>

                    {otherSubjects.length > 0 && (
                      <div className="journal-other-subjects">
                        <div style={{ color: "#666", marginBottom: 6 }}>Інші предмети</div>
                        <div style={{ display: "grid", gridTemplateColumns: "1fr", gap: 8 }}>
                          {otherSubjects.map((o, idx) => (
                            <div
                              key={idx}
                              className="subject-card"
                              role="button"
                              tabIndex={0}
                              title="Натисніть, щоб редагувати/видалити (шаблон)"
                              onClick={() => openActions(o.items[0])}
                              onKeyDown={(e) => {
                                if (e.key === "Enter" || e.key === " ") openActions(o.items[0]);
                              }}
                              style={{ display: "flex", justifyContent: "space-between", gap: 12, alignItems: "center", cursor: "pointer" }}
                            >
                              <div style={{ fontSize: 14 }}>
                                <div>{o.name}</div>
                                <div style={{ color: "#666", fontSize: 12 }}>
                                  {o.items.length > 1
                                    ? `${o.items.length} оцінки`
                                    : formatTime(o.items[0]?.lesson_date || o.items[0]?.date)}
                                </div>
                              </div>
                              <div style={{
                                fontWeight: 800,
                                padding: "6px 10px",
                                borderRadius: 8,
                                border: "1px solid #eee",
                                background: "white",
                                color: "#222",
                              }}>
                                {o.items[0]?.mark != null ? o.items[0].mark : o.items[0]?.status || "—"}
                              </div>
                            </div>
                          ))}
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
  );
}
