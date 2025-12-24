import axios from "axios";
import { redirect } from "react-router-dom";

const api = axios.create({
  baseURL: import.meta.env?.VITE_API_URL || "http://localhost:3000/api",
  timeout: 10000,
  headers: {
    "Content-Type": "application/json",
  },
});

api.interceptors.request.use(
  (config) => {
    const token = localStorage.getItem("accessToken");

    if (token) {
      config.headers.Authorization = `Bearer ${token}`;
    }
    if (import.meta.env?.VITE_API_DEV === 'true') {
      console.log(
        `-> ${config.method.toUpperCase()} ${config.url}`,
        config.params || config.data,
      );
    }

    return config;
  },
  (error) => {
    console.error("Request error:", error);
    return Promise.reject(error);
  },
);

api.interceptors.response.use(
  (response) => {
    if (import.meta.env?.VITE_API_DEV === 'true') {
      console.log(
        `<- ${response.config.method.toUpperCase()} ${response.config.url}`,
        response.data,
      );
    }
    return response;
  },
  (error) => {
    if (error.response?.status === 401) {
      console.log("Unauthorized - logging out");

      localStorage.removeItem("accessToken");

      redirect("/login");
    }

    if (error.response?.status === 403) {
      console.log("Access forbidden");
    }

    if (error.response?.status === 404) {
      console.log("Resource not found");
    }

    if (error.response?.status === 500) {
      console.log("Server error" + (error.response.data?.error ? `: ${error.response.data.error}` : ""));
    }

    if (!error.response) {
      console.log("Network error - server not reachable" + (error.message ? `: ${error.message}` : ""));
    }

    return Promise.reject(error);
  },
);

export default api;
