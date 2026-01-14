import api from "./lib/api.js";

function sanitizePayload(obj) {
  const out = {};
  if (!obj || typeof obj !== 'object') return out;
  Object.keys(obj).forEach((k) => {
    const v = obj[k];
    // treat empty string and undefined as explicit NULL for server-side
    if (v === '') {
      out[k] = null;
    } else if (v === undefined) {
      // skip undefined entirely so it's not sent
    } else {
      out[k] = v;
    }
  });
  return out;
}

export const getAllStudents = async () => {
  const request = await api.get("/students");

  return request.data.students;
};
export const getAllStudentsM = async () => {
  const request = await api.get("/students/m");
  return request.data.students;
};
export const getStudentAVGAbove7 = async () => {
  const request = await api.get("/students/avg-above-7");
  const data = request.data;
  return data;
};
export const getStudentByClass = async () => {
  const request = await api.get("/students/class");
  const data = request.data;
  return data.student ?? data;
};
export const getStudentRanking = async () => {
  const request = await api.get("/students/ranking");
  const data = request.data;
  return data;
};
export const getStudentPerformanceMatrix = async (studentId) => {
  const request = await api.get(`/students/performance-matrix/${studentId}`);
  const data = request.data;
  return data.students ?? data;
};
export const getStudentMonthlyMarks = async (studentId, month) => {
  // month should be a string in YYYY-MM-DD or YYYY-MM format, or null
  const request = await api.get(`/students/monthly-marks/${studentId}`, {
    params: { month },
  });
  return request.data;
};
export const getStudentByParentId = async (id) => {
  const request = await api.get(`/students/by-parent/${id}`);
  const data = request.data;
  return data.student ?? data;
};
export const getGradesAndAbsences = async (id) => {
  const request = await api.get(`/students/grades-and-absences/${id}`);

  return request.data;
};
export const getStudentsMarks = async () => {
  const request = await api.get("/students/marks");

  return request.data;
};
export const getStudentsAttendance = async (id) => {
  const resolvedId =
    typeof id === "object" && id !== null
      ? id.id ?? id.student_id ?? id.studentId ?? id.entity_id ?? id.entityId
      : id;

  const request = await api.get(`/students/attendance/${resolvedId}`);
  const data = request.data;
  if (Array.isArray(data)) return data;
  if (Array.isArray(data?.rows)) return data.rows;
  if (Array.isArray(data?.report)) return data.report;
  if (Array.isArray(data?.attendance)) return data.attendance;
  if (data && typeof data === "object") return [data];

  return data;
};
export const getStudentsDayPlan = async () => {
  const request = await api.get("/students/day-plan");

  return request.data;
};

export const getStudentById = async (id) => {
  const request = await api.get(`/students/${id}`);
  const data = request.data;
  return data.student ?? data;
};

export const createStudent = async ({
  name,
  surname,
  patronym,
  phone,
  class_c,
}) => {
  const body = sanitizePayload({ name, surname, patronym, phone, class_c });
  const request = await api.post("/students", body);

  return request;
};

export const createStudentWithUser = async ({
  name,
  surname,
  patronym,
  phone,
  class_c,
  user_id,
}) => {
  const body = sanitizePayload({
    name,
    surname,
    patronym,
    phone,
    class_c,
    user_id,
  });
  const request = await api.post("/students/user", body);

  return request;
};

export const patchStudent = async ({
  id,
  name,
  surname,
  patronym,
  phone,
  class_c,
}) => {
  const body = sanitizePayload({ id, name, surname, patronym, phone, class_c });
  const request = await api.patch(`/students/${id}`, body);

  return request;
};

export const deleteStudent = async (id) => {
  const request = await api.delete(`/students/${id}`);

  return request;
};
