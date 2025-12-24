import api from "./lib/api.js";

export const getParents = async () => {
  const request = await api.get("/parents");

  return request.data.parents;
};

export const getParentById = async (id) => {
  const request = await api.get(`/parents/${id}`);
  const data = request.data;
  return data.parent;
};

export const createParent = async ({ name, surname, patronym, phone }) => {
  const request = await api.post("/parents", {
    name,
    surname,
    patronym,
    phone,
  });

  return request;
};

export const patchParent = async ({
  id,
  name,
  surname,
  patronym,
  phone,
}) => {
  const request = await api.patch(`/parents/${id}`, {
    name,
    surname,
    patronym,
    phone,
  });

  return request;
};

export const deleteParent = async (id) => {
  const request = await api.delete(`/parents/${id}`);

  return request;
};
