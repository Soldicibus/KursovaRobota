import React, { useMemo, useState } from "react";
import { useNavigate, useParams } from "react-router-dom";
import { useCreateStudentData } from "../../../hooks/studentdata/mutations/useCreateStudentData";
import { useTeacherWithClassesName } from "../../../hooks/teachers/queries/useTeacherWithClassesName";
import TeacherStudentJournal from "./TeacherStudentJournal";
import StudentHomework from "../student/StudentHomework";
import StudentSchedule from "../student/StudentSchedule";
import { useCreateHomework } from "../../../hooks/homework/mutations/useCreateHomework";
import { useUpdateHomework } from "../../../hooks/homework/mutations/useUpdateHomework";
import { useDeleteHomework } from "../../../hooks/homework/mutations/useDeleteHomework";
import { useCreateLesson } from "../../../hooks/lessons/mutations/useCreateLesson";
import { useLessonName } from "../../../hooks/lessons/queries/useLessonName";
import { useSubjects } from "../../../hooks/subjects/queries/useSubjects";
import { useMaterials } from "../../../hooks/materials/queries/useMaterials";
import { useUserData } from "../../../hooks/users/queries/useUserData";
import { useHomeworkById } from "../../../hooks/homework/queries/useHomeworkById";
import { getCurrentUser } from "../../../utils/auth";
import ClassAbsentTab from "../common/ClassAbsentTab";

export default function TeacherClassView({ className: classNameProp, onBack }) {
  const navigate = useNavigate();

  const params = useParams();
  const rawFromRoute = params.class_name ?? params.className ?? params.id ?? "";
  const rawClassName = classNameProp ?? rawFromRoute;

  const className = useMemo(() => {
    if (!rawClassName) return "";
    try {
      return decodeURIComponent(rawClassName);
    } catch {
      // If it's already decoded or malformed, fall back to raw.
      return String(rawClassName);
    }
  }, [rawClassName]);

  const [tab, setTab] = useState("view"); // view | homework | schedule | absent

  // Persist selected class name to localStorage whenever it changes (if valid)
  React.useEffect(() => {
    if (className) {
      localStorage.setItem("teacher_selected_class_name", className);
    }
  }, [className]);

  const [selectedStudent, setSelectedStudent] = useState(null); // { id, name, surname }
  const [selectedHomework, setSelectedHomework] = useState(null);
  const [hwModal, setHwModal] = useState(null); // { type: 'create'|'edit'|'delete', data: ... }

  // Fetch full details of selected homework to ensure we have lesson_id
  const selectedHomeworkId = selectedHomework?.homework_id || selectedHomework?.id || selectedHomework?.homeworkId || null;
  const { data: fullSelectedHomework } = useHomeworkById(selectedHomeworkId);

  // --- Hooks for Homework CUD ---
  const currentUser = getCurrentUser();
  const userId = currentUser?.userId || currentUser?.id || currentUser?.sub || null;
  const { data: userRes } = useUserData(userId);
  const userData = userRes?.userData ?? userRes?.user ?? userRes ?? null;
  const teacherId = userData?.teacher_id || userData?.teacherId || userData?.entity_id || null;

  const createHomework = useCreateHomework();
  const updateHomework = useUpdateHomework();
  const deleteHomework = useDeleteHomework();
  const createLesson = useCreateLesson();

  const { data: subjects } = useSubjects();
  const { data: materials } = useMaterials();

  // For "Existing Lesson" search
  const [lessonSearch, setLessonSearch] = useState("");
  const { data: searchedLesson } = useLessonName(lessonSearch);

  // Form state for the modal
  const [hwForm, setHwForm] = useState({
    name: "",
    desc: "",
    due: "",
    lessonMode: "existing", // existing | new
    lessonNameSearch: "",
    newLessonName: "",
    newLessonSubject: "",
    newLessonMaterial: "",
    newLessonDate: "",
  });

  // Reset form when opening modal
  const openHwModal = (type, data = null) => {
    setHwModal({ type, data });
    setLessonSearch("");
    if (type === "create") {
      setHwForm({
        name: "",
        teacherId: teacherId,
        desc: "",
        date: "",
        lessonMode: "existing",
        lessonNameSearch: "",
        newLessonName: "",
        newLessonSubject: "",
        newLessonMaterial: "",
        newLessonDate: new Date().toISOString().slice(0, 16),
      });
    } else if (type === "edit" && data) {
      const rawDue = data.homework_duedate || data.due || "";
      const formattedDue = rawDue ? new Date(rawDue).toISOString().slice(0, 10) : "";
      setHwForm({
        name: data.homework_name || data.title || "",
        desc: data.homework_desc || data.desc || "",
        due: formattedDue,
        // Edit mode usually doesn't change lesson, but we keep the fields just in case
        lessonMode: "existing",
        lessonNameSearch: "", 
        newLessonName: "",
        newLessonSubject: "",
        newLessonMaterial: "",
        newLessonDate: "",
      });
    }
  };

  const createStudentData = useCreateStudentData();

  const {
    data,
    isLoading,
    error,
    isError,
  } = useTeacherWithClassesName(className);

  const rows = useMemo(() => {
    if (isLoading) return [];
    if (Array.isArray(data)) return data;
    return data?.rows ?? data?.report ?? [];
  }, [data, isLoading]);

  const anyStudentId = useMemo(() => {
    const first = rows?.[0];
    return first?.id ?? first?.student_id ?? null;
  }, [rows]);

  const classTitle =
    rows?.[0]?.class_name ||
    (className ? `Клас ${className}` : "Клас");

  const onSubmit = async (e) => {
    e.preventDefault();

    await createStudentData.mutateAsync([
      form.journalId || null,
      form.studentId || null,
      form.lesson || null,
      form.mark || null,
      form.status || null,
      form.note || null,
    ]);
  };

  const renderHwModal = () => {
    if (!hwModal) return null;

    const overlayStyle = {
      position: "fixed",
      inset: 0,
      background: "rgba(0,0,0,0.45)",
      display: "flex",
      alignItems: "center",
      justifyContent: "center",
      zIndex: 1000,
      padding: 16,
      color: '#000',
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
    const closeModal = () => setHwModal(null);

    const handleCreateSubmit = async () => {
      try {
        let lessonId = null;

        if (hwForm.lessonMode === "new") {
          // Create new lesson
          const newLessonRes = await createLesson.mutateAsync({
            name: hwForm.newLessonName,
            className: className, // from context
            subjectId: hwForm.newLessonSubject,
            materialId: hwForm.newLessonMaterial,
            teacherId: teacherId,
            date: hwForm.newLessonDate || new Date().toISOString(),
          });
          
          // The API returns the axios response object, so we need to access .data
          const resData = newLessonRes?.data || newLessonRes;
          lessonId = resData?.lessonId || resData?.id || resData?.insertId;
        } else {
          // Existing lesson
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

        await createHomework.mutateAsync({
          name: hwForm.name,
          teacherId: teacherId,
          lessonId: lessonId,
          dueDate: hwForm.due,
          description: hwForm.desc,
          className: className,
        });
        closeModal();
      } catch (err) {
        console.error(err);
        alert("Error creating homework: " + err.message);
      }
    };

    const handleUpdateSubmit = async () => {
      try {
        console.log("Updating homework - debug point 1");
        const hwId = hwModal.data?.homework_id;
        console.log("Updating homework - debug point 2, hwId:", hwId);
        if (!hwId) {
          alert("Error: Homework ID is missing.");
          return;
        }

        if (!teacherId) {
          alert("Error: Teacher ID is missing. Please wait for user data to load.");
          return;
        }

        // For update, we keep the existing lesson_id unless we want to support changing it.
        // The prompt says "lesson_id (get from useHomework(homework_id))".
        // We'll use the one from the selected data.
        let originalLessonId = hwModal.data?.lesson_id || hwModal.data?.homework_lesson;

        if (!originalLessonId) {
          // Try to fetch full details if lesson_id is missing in the view
          // We use the data from the hook which should be loaded by now
          originalLessonId = fullSelectedHomework?.homework?.lesson_id || fullSelectedHomework?.homework?.homework_lesson;
        }

        if (!originalLessonId) {
          alert("Error: Lesson ID is missing on the selected homework. Cannot update.");
          return;
        }

        console.log("Updating homework:", {
          id: hwId,
          name: hwForm.name,
          teacherId: teacherId,
          lessonId: originalLessonId, 
          dueDate: hwForm.due,
          description: hwForm.desc,
          className: className,
        });

        await updateHomework.mutateAsync({
          id: hwId,
          name: hwForm.name,
          teacherId: teacherId,
          lessonId: originalLessonId, 
          dueDate: hwForm.due,
          description: hwForm.desc,
          className: className,
        });
        closeModal();
      } catch (err) {
        console.error(err);
        alert("Error updating homework: " + err.message);
      }
    };

    const handleDeleteSubmit = async () => {
      try {
        const hwId = hwModal.data?.homework_id || hwModal.data?.id || hwModal.data?.homeworkId;
        if (!hwId) return;
        await deleteHomework.mutateAsync(hwId);
        setSelectedHomework(null); // clear selection
        closeModal();
      } catch (err) {
        console.error(err);
        alert("Error deleting homework: " + err.message);
      }
    };

    if (hwModal.type === "create") {
      return (
        <div style={overlayStyle}>
          <div style={boxStyle} onClick={stop}>
            <div style={headerStyle}>
              <div>
                <div style={titleStyle}>Створити домашнє завдання</div>
                <div style={subStyle}>Нове завдання для класу {className}</div>
              </div>
              <button type="button" onClick={closeModal} style={btnStyle}>✕</button>
            </div>
            <div style={{ display: "grid", gap: 10, maxHeight: "70vh", overflowY: "auto" }}>
              {/* Common Fields */}
              <label style={{ display: "grid", gap: 6 }}>
                <div style={{ fontWeight: 700 }}>Заголовок</div>
                <input 
                  value={hwForm.name}
                  onChange={e => setHwForm({...hwForm, name: e.target.value})}
                  placeholder="Напр., Вправа 42" 
                  style={{ padding: 10, borderRadius: 10, border: "1px solid #e6e6e6" }} 
                />
              </label>
              <label style={{ display: "grid", gap: 6 }}>
                <div style={{ fontWeight: 700 }}>Опис</div>
                <textarea 
                  rows={3} 
                  value={hwForm.desc}
                  onChange={e => setHwForm({...hwForm, desc: e.target.value})}
                  placeholder="Деталі завдання..." 
                  style={{ padding: 10, borderRadius: 10, border: "1px solid #e6e6e6" }} 
                />
              </label>
              <label style={{ display: "grid", gap: 6 }}>
                <div style={{ fontWeight: 700 }}>Термін здачі</div>
                <input 
                  type="date" 
                  value={hwForm.due}
                  onChange={e => setHwForm({...hwForm, due: e.target.value})}
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
                      checked={hwForm.lessonMode === "existing"} 
                      onChange={() => setHwForm({...hwForm, lessonMode: "existing"})}
                    />
                    Існуючий урок
                  </label>
                  <label style={{ display: "flex", gap: 6, alignItems: "center", cursor: "pointer" }}>
                    <input 
                      type="radio" 
                      name="lessonMode" 
                      checked={hwForm.lessonMode === "new"} 
                      onChange={() => setHwForm({...hwForm, lessonMode: "new"})}
                    />
                    Створити новий
                  </label>
                </div>

                {hwForm.lessonMode === "existing" ? (
                  <label style={{ display: "grid", gap: 6 }}>
                    <div style={{ fontSize: 13, opacity: 0.8 }}>Назва уроку (пошук)</div>
                    <input 
                      value={hwForm.lessonNameSearch}
                      onChange={e => {
                        setHwForm({...hwForm, lessonNameSearch: e.target.value});
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
                        value={hwForm.newLessonName}
                        onChange={e => setHwForm({...hwForm, newLessonName: e.target.value})}
                        placeholder="Напр., Вступ до алгебри"
                        style={{ padding: 8, borderRadius: 8, border: "1px solid #e6e6e6" }}
                      />
                    </label>
                    <label style={{ display: "grid", gap: 4 }}>
                      <div style={{ fontSize: 13 }}>Предмет</div>
                      <select 
                        value={hwForm.newLessonSubject}
                        onChange={e => setHwForm({...hwForm, newLessonSubject: e.target.value})}
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
                        value={hwForm.newLessonMaterial}
                        onChange={e => setHwForm({...hwForm, newLessonMaterial: e.target.value})}
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
                        value={hwForm.newLessonDate}
                        onChange={e => setHwForm({...hwForm, newLessonDate: e.target.value})}
                        style={{ padding: 8, borderRadius: 8, border: "1px solid #e6e6e6" }}
                      />
                    </label>
                  </div>
                )}
              </div>

            </div>
            <div style={buttonRowStyle}>
              <button type="button" style={btnStyle} onClick={closeModal}>Скасувати</button>
              <button type="button" style={btnPrimaryStyle} onClick={handleCreateSubmit}>Створити</button>
            </div>
          </div>
        </div>
      );
    }

    if (hwModal.type === "edit") {
      const { data } = hwModal;
      return (
        <div style={overlayStyle} onClick={closeModal}>
          <div style={boxStyle} onClick={stop}>
            <div style={headerStyle}>
              <div>
                <div style={titleStyle}>Редагувати домашнє завдання</div>
                <div style={subStyle}>{data?.homework_name || data?.title}</div>
              </div>
              <button type="button" onClick={closeModal} style={btnStyle}>✕</button>
            </div>
             <div style={{ display: "grid", gap: 10 }}>
              <label style={{ display: "grid", gap: 6 }}>
                <div style={{ fontWeight: 700 }}>Заголовок</div>
                <input 
                  value={hwForm.name}
                  onChange={e => setHwForm({...hwForm, name: e.target.value})}
                  style={{ padding: 10, borderRadius: 10, border: "1px solid #e6e6e6" }} 
                />
              </label>
              <label style={{ display: "grid", gap: 6 }}>
                <div style={{ fontWeight: 700 }}>Опис</div>
                <textarea 
                  rows={3} 
                  value={hwForm.desc}
                  onChange={e => setHwForm({...hwForm, desc: e.target.value})}
                  style={{ padding: 10, borderRadius: 10, border: "1px solid #e6e6e6" }} 
                />
              </label>
              <label style={{ display: "grid", gap: 6 }}>
                <div style={{ fontWeight: 700 }}>Термін здачі</div>
                <input 
                  type="date" 
                  value={hwForm.due}
                  onChange={e => setHwForm({...hwForm, due: e.target.value})}
                  style={{ padding: 10, borderRadius: 10, border: "1px solid #e6e6e6" }} 
                />
              </label>
            </div>
            <div style={buttonRowStyle}>
              <button type="button" style={btnStyle} onClick={closeModal}>Скасувати</button>
              <button type="button" style={btnPrimaryStyle} onClick={handleUpdateSubmit}>Зберегти</button>
            </div>
          </div>
        </div>
      );
    }

    if (hwModal.type === "delete") {
      const { data } = hwModal;
      return (
        <div style={overlayStyle} onClick={closeModal}>
          <div style={boxStyle} onClick={stop}>
            <div style={headerStyle}>
              <div>
                <div style={titleStyle}>Видалити домашнє завдання?</div>
                <div style={subStyle}>{data?.homework_name || data?.title}</div>
              </div>
              <button type="button" onClick={closeModal} style={btnStyle}>✕</button>
            </div>
            <div style={{ opacity: 0.9 }}>Цю дію не можна буде скасувати.</div>
            <div style={buttonRowStyle}>
              <button type="button" style={btnStyle} onClick={closeModal}>Скасувати</button>
              <button type="button" style={btnDangerStyle} onClick={() => { handleDeleteSubmit(); closeModal(); }}>Видалити</button>
            </div>
          </div>
        </div>
      );
    }

    return null;
  };

  return (
    <main className="main">
      <div style={{ display: "flex", gap: 10, alignItems: "center" }}>
        <h1 style={{ margin: 0 }}>{classTitle}</h1>
      </div>

      {isLoading && <div>Завантаження...</div>}

      {isError && !isLoading && (
        <div style={{ marginTop: 10, color: "crimson" }}>
          Помилка завантаження учнів
          {error?.message ? `: ${error.message}` : ""}
        </div>
      )}

      {!isLoading && (
        <div className="tabs" style={{ marginTop: 8 }}>
          <button
            onClick={() => setTab("view")}
            className={tab === "view" ? "active" : ""}
          >
            Перегляд
          </button>
          <button
            onClick={() => setTab("homework")}
            className={tab === "homework" ? "active" : ""}
          >
            Домашні
          </button>
          <button
            onClick={() => setTab("schedule")}
            className={tab === "schedule" ? "active" : ""}
          >
            Розклад
          </button>
          <button
            onClick={() => setTab("absent")}
            className={tab === "absent" ? "active" : ""}
          >
            Відсутність
          </button>
        </div>
      )}

      {tab === "absent" && <ClassAbsentTab className={className} />}

      {tab === "view" && (
        <>
          <section className="card">
            {selectedStudent ? (
              <TeacherStudentJournal
                studentId={selectedStudent.id}
                studentName={`${selectedStudent.surname || ""} ${
                  selectedStudent.name || ""
                }`.trim()}
                onBack={() => setSelectedStudent(null)}
              />
            ) : (
              <>
                <h2>Учні</h2>

                {isLoading && <div>Завантаження списку учнів...</div>}
                {isError && (
                  <div style={{ color: "crimson" }}>
                    Помилка завантаження учнів
                    {error?.message ? `: ${error.message}` : ""}
                  </div>
                )}

                <div
                  style={{
                    marginTop: 10,
                    gridGap: 6,
                    gridTemplateColumns: "1fr 1fr 1fr",
                    display: "grid",
                  }}
                >
                  {rows.length ? (
                    rows.map((s, idx) => {
                      const id = s.id ?? s.student_id ?? null;
                      const key = id ?? idx;
                      const name =
                        s.student_name ||
                        s.name ||
                        s.username ||
                        s.first_name ||
                        "";
                      const surname =
                        s.student_surname || s.surname || s.last_name || "";

                      return (
                        <button
                          key={key}
                          type="button"
                          onClick={() =>
                            setSelectedStudent({
                              id: id ?? key,
                              name,
                              surname,
                            })
                          }
                          title="Відкрити журнал учня"
                        >
                          {surname} {name}
                        </button>
                      );
                    })
                  ) : (
                    <div style={{ opacity: 0.8 }}>
                      Немає даних про учнів у відповіді класу.
                    </div>
                  )}
                </div>
              </>
            )}
          </section>
        </>
      )}

      {tab === "schedule" && (
        <section className="card">
          <h2>Розклад</h2>
          {anyStudentId ? (
            <StudentSchedule studentId={anyStudentId} />
          ) : (
            <div style={{ padding: 20, opacity: 0.7 }}>
              У цьому класі немає учнів, щоб завантажити домашні завдання.
            </div>
          )}
        </section>
      )}

      {tab === "homework" && (
        <section className="card">
          {renderHwModal()}
          <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center", marginBottom: 16 }}>
            <h2 style={{ margin: 0 }}>Домашні</h2>
            <div style={{ display: "flex", gap: 8 }}>
              <button onClick={() => openHwModal('create')}>+ Створити</button>
              <button disabled={!selectedHomework} onClick={() => openHwModal('edit', selectedHomework)}>Редагувати</button>
              <button disabled={!selectedHomework} onClick={() => openHwModal('delete', selectedHomework)}>Видалити</button>
            </div>
          </div>
          {anyStudentId ? (
            <StudentHomework 
              studentId={anyStudentId} 
              onSelect={(hw) => setSelectedHomework(hw)}
            />
          ) : (
            <div style={{ padding: 20, opacity: 0.7 }}>
              У цьому класі немає учнів, щоб завантажити домашні завдання.
            </div>
          )}
        </section>
      )}
    </main>
  );
}
