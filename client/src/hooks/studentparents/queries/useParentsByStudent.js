import { useQuery } from "@tanstack/react-query";
import * as studentparentsAPI from "../../../api/studentparentsAPI.js";

export function useParentsByStudent(studentId) {
  return useQuery({
    queryKey: ["studentparents", studentId],
    queryFn: () => studentparentsAPI.getParentsByStudentId(studentId),
    enabled: !!studentId,
  });
}