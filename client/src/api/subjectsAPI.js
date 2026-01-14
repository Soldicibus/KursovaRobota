import api from "./lib/api.js";

export const getAllSubjects = async () => {
  const request = await api.get("/subjects");

  return request.data.subjects;
};

export const createSubject = async ({ name, program, cabinet }) => {
  const request = await api.post("/subjects", {
    name,
    program,
    cabinet,
  });

  return request;
};

export const patchSubject = async ({ id, name, program, cabinet }) => {
  const request = await api.patch(`/subjects/${id}`, {
    name,
    program,
    cabinet,
  });

  return request;
};

export const deleteSubject = async (id) => {
  const request = await api.delete(`/subjects/${id}`);

  return request;
};
