import api from "./lib/api.js";

export const getParentsByStudentId = async (studentId) => {
  const request = await api.get(`/studentparents/${studentId}`);
  const data = request.data;
  return data.parents ?? data;
};

export const getChildren = async (parentId) => {
  const request = await api.get(`/studentparents/children/${parentId}`);
  const data = request.data;
  return data.students ?? data;
}

export const assignParentToStudent = async (studentIdOrObj, parentId) => {
  let studentId = studentIdOrObj;
  let pId = parentId;
  if (studentIdOrObj && typeof studentIdOrObj === 'object') {
    studentId = studentIdOrObj.studentId;
    pId = studentIdOrObj.parentId;
  }
  const request = await api.post("/studentparents/assign", {
    studentId,
    parentId: pId,
  });
  return request;
};

export const unassignParentFromStudent = async (studentId, parentId) => {
  const request = await api.delete("/studentparents/unassign", {
    studentId,
    parentId,
  });
  return request;
};
