import api from "./lib/api.js";

export const getAllLessons = async () => {
  const request = await api.get("/lessons");
  return request.data.lessons;
};

export const getLessonById = async (id) => {
  const request = await api.get(`/lessons/${id}`);
  const data = request.data;
  return data.lesson;
};

export const getLessonByName = async (name) => {
  let decoded = name;
  try {
    decoded = decodeURIComponent(name);
  } catch {
    decoded = name;
  }
  const safeSegment = encodeURIComponent(decoded);
  const request = await api.get(`/lessons/name/${safeSegment}`);
  const data = request.data;
  return data.lesson;
};

export const createLesson = async ({
  name,
  className,
  subjectId,
  materialId,
  teacherId,
  date,
}) => {
  const request = await api.post("/lessons", {
    name,
    className,
    subjectId,
    materialId,
    teacherId,
    date,
  });
  return request;
};

export const updateLesson = async ({
  id,
  name,
  className,
  subjectId,
  materialId,
  teacherId,
  date,
}) => {
  const request = await api.patch(`/lessons/${id}`, {
    name,
    className,
    subjectId,
    materialId,
    teacherId,
    date,
  });
  return request;
};

export const deleteLesson = async (id) => {
  const request = await api.delete(`/lessons/${id}`);
  return request;
};
