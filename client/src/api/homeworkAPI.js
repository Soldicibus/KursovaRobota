import api from "./lib/api.js";

export const getAllHomework = async () => {
  const request = await api.get("/homework");
  const data = request.data;
  return data?.homework ?? data?.rows ?? data;
};

export const getHomeworkById = async (id) => {
  const request = await api.get(`/homework/${id}`);
  return request.data;
};

export const getHomeworkByStudentOrClass = async (studentId) => {
  const request = await api.get(`/homework/by-student-or-class/${studentId}`);
  const data = request.data;
  return data?.homework ?? data?.rows ?? data;
};

export const getHomeworkForTomorrow = async () => {
  const request = await api.get("/homework/for-tomorrow");
  const data = request.data;
  return data?.homework ?? data?.rows ?? data;
};

export const createHomework = async ({
  name,
  teacherId,
  lessonId,
  dueDate,
  description,
  className,
}) => {
  const request = await api.post("/homework", {
    name,
    teacherId,
    lessonId,
    dueDate,
    description,
    className,
  });
  return request.data;
};

export const updateHomework = async ({
  id,
  name,
  teacherId,
  lessonId,
  dueDate,
  description,
  className,
}) => {
  const request = await api.patch(`/homework/${id}`, {
    name,
    teacherId,
    lessonId,
    dueDate,
    description,
    className,
  });
  return request.data;
};

export const deleteHomework = async (id) => {
  const request = await api.delete(`/homework/${id}`);
  return request.data;
};
