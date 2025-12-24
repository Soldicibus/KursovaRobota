import api from "./lib/api.js";

export const getAllClasses = async () => {
  const request = await api.get("/classes");
  return request.data.classes;
};

export const getClassByName = async (name) => {
  let decoded = name;
  try {
    decoded = decodeURIComponent(name);
  } catch {
    decoded = name;
  }
  const safeSegment = encodeURIComponent(decoded);
  const request = await api.get(`/classes/${safeSegment}`);
  const data = request.data;
  return data.class;
};

export const getClassRatingReport = async () => {
  const request = await api.get(`/classes/rate/rating`);
  return request.data.report;
};

export const createClass = async ({ name, journalId, mainTeacherId }) => {
  const request = await api.post("/classes", {
    name,
    journalId,
    mainTeacherId,
  });
  return request;
};

export const getClassAbsentReport = async (name, amount) => {
  let decoded = name;
  try {
    decoded = decodeURIComponent(name);
  } catch {
    decoded = name;
  }
  const safeSegment = encodeURIComponent(decoded);
  const request = await api.get(`/classes/absent/${safeSegment}/${amount}`);
  return request.data.report;
};

export const updateClass = async ({ newName, name, journalId, mainTeacherId }) => {
  let decoded = name;
  try {
    decoded = decodeURIComponent(name);
  } catch {
    decoded = name;
  }
  const safeSegment = encodeURIComponent(decoded);
  const request = await api.patch(`/classes/${safeSegment}`, {
    name,
    newName,
    journalId,
    mainTeacherId,
  });
  return request;
};

export const deleteClass = async (name) => {
  let decoded = name;
  try {
    decoded = decodeURIComponent(name);
  } catch {
    decoded = name;
  }
  const safeSegment = encodeURIComponent(decoded);
  const request = await api.delete(`/classes/${safeSegment}`);
  return request;
};
