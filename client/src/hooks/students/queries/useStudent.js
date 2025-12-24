import { useQuery } from "@tanstack/react-query";
import * as studentAPI from "../../../api/studentAPI.js";

export function useStudent(id) {
  return useQuery({
    queryKey: ["student", id],
    queryFn: () => studentAPI.getStudentById(id),
    enabled: !!id,
  });
}