import api from "./lib/api.js";

export const getAllSubjects = async () => {
  const request = await api.get("/subjects");

  return request.data.subjects;
};

export const createSubject = async ({ name, program }) => {
  const request = await api.post("/subjects", {
    name,
    program,
  });

  return request;
};

export const deleteSubject = async (id) => {
  const request = await api.delete(`/subjects/${id}`);

  return request;
};
