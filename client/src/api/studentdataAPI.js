import api from "./lib/api.js";

export const getAllStudentData = async () => {
  const request = await api.get("/studentdata");
  return request.data.studentData;
};

export const getStudentDataById = async (id) => {
  const request = await api.get(`/studentdata/${id}`);
  const data = request.data;
  return data.studentData ?? data;
};

export const getStudentDataMarks7d = async (studentId) => {
  const request = await api.get(`/studentdata/journal/${studentId}`);
  return request.data.marks;
};

export const createStudentData = async ({
  journalId,
  studentId,
  lesson,
  mark,
  status,
  note,
}) => {
  const request = await api.post("/studentdata", {
    journalId,
    studentId,
    lesson,
    mark,
    status,
    note,
  });
  return request;
};

export const updateStudentData = async ({
  id,
  journalId,
  studentId,
  lesson,
  mark,
  status,
  note,
}) => {
  const request = await api.patch(`/studentdata/${id}`, {
    journalId,
    studentId,
    lesson,
    mark,
    status,
    note,
  });
  return request;
};

export const deleteStudentData = async (id) => {
  const request = await api.delete(`/studentdata/${id}`);
  return request;
};
