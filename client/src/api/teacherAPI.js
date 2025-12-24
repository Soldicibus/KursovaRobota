import api from "./lib/api.js";

export const getTeachers = async () => {
  const request = await api.get("/teacher");

  return request.data.teachers;
};

export const getTeacherSalaryReport = async (id, fromDate, toDate) => {
  const request = await api.get(`/teacher/salary/${id}/${fromDate}/${toDate}`);

  return request.data.salary;
};

export const getTeachersWithClasses = async (id) => {
  const request = await api.get(`/teacher/with-classes/${id}`);

  return request.data.teachers;
};

export const getTeachersWithClassesByName = async (className) => {
  let decoded = className;
  try {
    decoded = decodeURIComponent(className);
  } catch {
    decoded = className;
  }
  const safeSegment = encodeURIComponent(decoded);
  const request = await api.get(`/teacher/with-classes-by-name/${safeSegment}`);

  return request.data.teachers;
};

export const getTeacherById = async (id) => {
  const request = await api.get(`/teacher/${id}`);
  const data = request.data;
  return data.teacher ?? data;
};

export const createTeacher = async ({ name, surname, patronym, phone }) => {
  const request = await api.post("/teacher", {
    name,
    surname,
    patronym,
    phone,
  });
  return request;
};

export const patchTeacher = async ({
  id,
  name,
  surname,
  patronym,
  phone,
}) => {
  const request = await api.patch(`/teacher/${id}`, {
    name,
    surname,
    patronym,
    phone,
  });

  return request;
};

export const deleteTeacher = async (id) => {
  const request = await api.delete(`/teacher/${id}`);

  return request;
};
