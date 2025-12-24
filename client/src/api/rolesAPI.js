import api from "./lib/api.js";

export const getAllRoles = async () => {
  const request = await api.get("/roles");
  return request.data.roles;
};

export const getRoleById = async (id) => {
  const request = await api.get(`/roles/${id}`);
  const data = request.data;
  return data.role;
};

export const createRole = async (roleName) => {
  const request = await api.post("/roles", {
    roleName,
  });

  return request;
};

export const updateRole = async (id, roleName) => {
  const request = await api.patch(`/roles/${id}`, {
    roleName,
  });

  return request;
};

export const deleteRole = async (id) => {
  const request = await api.delete(`/roles/${id}`);

  return request;
};
