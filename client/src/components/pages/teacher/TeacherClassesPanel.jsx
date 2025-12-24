import React, { useEffect, useMemo } from "react";
import { useNavigate } from "react-router-dom";
import { getCurrentUser } from "../../../utils/auth";
import { useUserData } from "../../../hooks/users";
import { useTeachersWithClasses } from "../../../hooks/teachers/queries/useTeachersWithClasses";
import { useClasses } from "../../../hooks/classes/queries/useClasses";

/**
 * @param {object} props
 * @param {boolean} [props.onlyMyClasses] If true, only show classes for current teacher.
 * @param {string|null} [props.selectedClassName] Currently selected class name.
 * @param {(className:string)=>void} [props.onSelectClassName] Callback when a class name is selected.
 * @param {(info:{teacherId:any, entityId:any, myClasses:string[], allRows:any[]})=>void} [props.onLoaded] Called when data is ready.
 */
export default function TeacherClassesPanel({
  onlyMyClasses = false,
  selectedClassName = null,
  onSelectClassName,
  onLoaded,
}) {
  const navigate = useNavigate();

  const currentUser = getCurrentUser();
  const userId = currentUser?.userId || currentUser?.id || currentUser?.sub || null;

  const {
    data: userRes,
    isLoading: isUserLoading,
    error: userErr,
  } = useUserData(userId);
  const user = userRes?.userData ?? userRes?.user ?? userRes ?? null;

  const entityId = user?.entity_id ?? user?.entityId ?? userRes?.entity_id ?? null;

  // All classes (dashboard "Усі класи")
  const {
    data: allClassesRes,
    isLoading: isAllClassesLoading,
    error: allClassesErr,
  } = useClasses();

  const allClasses = useMemo(() => {
    const data = allClassesRes;
    const list = Array.isArray(data?.classes)
      ? data.classes
      : Array.isArray(data)
        ? data
        : [];

    const names = list
      .map((c) => c?.class_name ?? c?.name ?? c)
      .filter(Boolean);

    return Array.from(new Set(names)).sort((a, b) =>
      String(a).localeCompare(String(b), "uk"),
    );
  }, [allClassesRes]);

  // Teacher's classes (dashboard "Мій клас")
  const {
    data: teachersWithClassesRes,
    isLoading: isTwcLoading,
    error: twcErr,
  } = useTeachersWithClasses(entityId);

  const teachersWithClasses = useMemo(() => {
    const data = teachersWithClassesRes;
    if (!data) return [];
    if (Array.isArray(data)) return data;
    return data.teachers ?? [];
  }, [teachersWithClassesRes]);

  const myTeacherId =
    user?.teacher_id || user?.teacherId || entityId || null;

  const myClasses = useMemo(() => {
    if (!myTeacherId) return [];
    const set = new Set();
    for (const row of teachersWithClasses) {
      const rowTeacherId = row.teacher_id ?? row.id;
      if (!rowTeacherId) continue;
      if (String(rowTeacherId) !== String(myTeacherId)) continue;
      const className = row.class_name || row.name_class || row.class;
      if (className) set.add(className);
    }
    return Array.from(set).sort((a, b) => String(a).localeCompare(String(b), "uk"));
  }, [teachersWithClasses, myTeacherId]);

  useEffect(() => {
    if (isUserLoading || userErr) return;
    if (!onlyMyClasses) {
      if (isAllClassesLoading || allClassesErr) return;
    } else {
      if (isTwcLoading || twcErr) return;
    }
    if (typeof onLoaded !== "function") return;
    onLoaded({
      teacherId: myTeacherId,
      entityId,
      myClasses,
      allRows: teachersWithClasses,
    });
  }, [
    isUserLoading,
    userErr,
    isAllClassesLoading,
    allClassesErr,
    isTwcLoading,
    twcErr,
    onlyMyClasses,
    myTeacherId,
    entityId,
    myClasses,
    teachersWithClasses,
    // onLoaded is intentionally omitted to avoid loops if it's not memoized
  ]);

  const visibleClasses = onlyMyClasses ? myClasses : allClasses;

  const visibleClassesSorted = useMemo(() => {
    const parseLeadingNumber = (val) => {
      const m = String(val ?? "").trim().match(/^(\d+)/);
      return m ? Number(m[1]) : Number.POSITIVE_INFINITY;
    };

    return [...visibleClasses].sort((a, b) => {
      const an = parseLeadingNumber(a);
      const bn = parseLeadingNumber(b);
      if (an !== bn) return an - bn;
      return String(a).localeCompare(String(b), "uk", {
        numeric: true,
        sensitivity: "base",
      });
    });
  }, [visibleClasses]);

  const isLoading = onlyMyClasses
    ? isUserLoading || isTwcLoading
    : isUserLoading || isAllClassesLoading;

  const err = onlyMyClasses
    ? userErr || twcErr
    : userErr || allClassesErr;

  return (
    <section className="card">
      <h2>{onlyMyClasses ? "Мій клас / Мої класи" : "Усі класи"}</h2>

      {isLoading && <div>Завантаження...</div>}
      {err && (
        <div>
          Помилка завантаження
          {err?.message ? `: ${err.message}` : ""}
        </div>
      )}

      {!isLoading && !err && (
        <>
          {onlyMyClasses && !myTeacherId ? (
            <p style={{ opacity: 0.85 }}>
              Не вдалося визначити teacher id. Перевірте, що `/users/:id/data`
              повертає `entity_id` для ролі Teacher.
            </p>
          ) : visibleClasses.length === 0 ? (
            <p>{onlyMyClasses ? "Для вас не знайдено класів." : "Класи не знайдено."}</p>
          ) : (
            <div
              style={{
                display: "grid",
                gridTemplateColumns: "repeat(4, minmax(0, 1fr))",
                gap: 10,
                marginTop: 10,
              }}
            >
              {visibleClassesSorted.map((c) => (
                <button
                  key={c}
                  onClick={() => {
                    if (typeof onSelectClassName === "function") {
                      onSelectClassName(c);
                      return;
                    }
                    // Encode to keep URLs safe for values like "2-А".
                    const encoded = encodeURIComponent(String(c));
                    navigate(`/teacher/classes/${encoded}`);
                  }}
                  className={
                    selectedClassName && String(selectedClassName) === String(c)
                      ? "active"
                      : ""
                  }
                  style={{
                    width: "100%",
                    textAlign: "center",
                    padding: "10px 12px",
                  }}
                >
                  {c}
                </button>
              ))}
            </div>
          )}
        </>
      )}
    </section>
  );
}
