import api from "./lib/api.js";

export const getUserRoles = async () => {
  const request = await api.get("/userroles");

  return request.data;
};

export const getRolesByUserId = async (userId) => {
  const request = await api.get(`/userroles/${userId}`);

  return request.data;
};

export const assignRole = async (userId, roleId) => {
  const request = await api.post("/userroles/assign", {
    userId,
    roleId,
  });

  return request.data;
};

export const removeRoleFromUser = async (userId, roleId) => {
  const request = await api.delete("/userroles/remove", {
    data: { userId, roleId },
  });

  return request;
};

export const getUserRole = async (userId) => {
  const request = await api.get(`/userroles/role/${userId}`);

  return request.data;
};
