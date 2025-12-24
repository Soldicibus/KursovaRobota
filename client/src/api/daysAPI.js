import api from "./lib/api.js";

export const getAllDays = async () => {
  const request = await api.get("/days");
  return request.data.days;
};

export const getDayById = async (id) => {
  const request = await api.get(`/days/${id}`);
  const data = request.data;
  return data.day;
};

export const createDay = async ({ subjectId, timetableId, dayTime, dayWeekday }) => {
  const request = await api.post("/days", {
    subjectId,
    timetableId,
    dayTime,
    dayWeekday,
  });
  return request;
};

export const updateDay = async ({ id, subjectId, timetableId, dayTime, dayWeekday }) => {
  const request = await api.patch(`/days/${id}`, {
    subjectId,
    timetableId,
    dayTime,
    dayWeekday,
  });
  return request;
};

export const deleteDay = async (id) => {
  const request = await api.delete(`/days/${id}`);
  return request;
};
