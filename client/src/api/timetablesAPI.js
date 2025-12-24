import api from "./lib/api.js";

export const getAllTimetables = async () => {
  const request = await api.get("/timetables");
  return request.data.timetables;
};

export const getWeeklyTimetable = async (id) => {
  const request = await api.get(`/timetables/week/${id}`);
  const data = request.data;
  return data?.timetable ?? data?.weekRows ?? data?.rows ?? data;
};

export const getTimetableByStudentId = async (id) => {
  const request = await api.get(`/timetables/student/${id}`);
  const data = request.data;
  return data?.timetable ?? data?.timetables ?? data;
};

export const getTimetableById = async (id) => {
  const request = await api.get(`/timetables/${id}`);
  return request.data.timetable ?? request.data;
};

export const createTimetable = async ({ name, class_name }) => {
  const request = await api.post("/timetables", {
    name,
    class_name,
  });
  return request;
};

export const updateTimetable = async ({ id, name, class_name }) => {
  const request = await api.patch(`/timetables/${id}`, {
    name,
    class_name,
  });
  return request;
};

export const deleteTimetable = async (id) => {
  const request = await api.delete(`/timetables/${id}`);
  return request;
};
