import api from "./lib/api.js";

export const getAllMaterials = async () => {
  const request = await api.get("/materials");
  return request.data.materials;
};

export const getMaterialById = async (id) => {
  const request = await api.get(`/materials/${id}`);
  const data = request.data;
  return data.material;
};

export const createMaterial = async ({ name, description, link }) => {
  const request = await api.post("/materials", {
    name,
    description,
    link,
  });
  return request;
};

export const updateMaterial = async ({ id, name, description, link }) => {
  const request = await api.patch(`/materials/${id}`, {
    name,
    description,
    link,
  });
  return request;
};

export const deleteMaterial = async (id) => {
  const request = await api.delete(`/materials/${id}`);
  return request;
};
