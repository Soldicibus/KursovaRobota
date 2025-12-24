import api from "./lib/api.js";

export const getAllJournals = async () => {
  const request = await api.get("/journals");
  return request.data.journals;
};

export const getJournalById = async (id) => {
  const request = await api.get(`/journals/${id}`);
  const data = request.data;
  return data.journal;
};

export const getJournalByStudent = async (studentId) => {
  const request = await api.get(`/journals/student/${studentId}`);
  const data = request.data;
  return data.journals;
};

export const createJournal = async ({ teacherId, name }) => {
  const request = await api.post("/journals", {
    teacherId,
    name,
  });
  return request;
};

export const updateJournal = async ({ id, teacherId, name }) => {
  const request = await api.patch(`/journals/${id}`, {
    teacherId,
    name,
  });
  return request;
};

export const deleteJournal = async (id) => {
  const request = await api.delete(`/journals/${id}`);
  return request;
};
