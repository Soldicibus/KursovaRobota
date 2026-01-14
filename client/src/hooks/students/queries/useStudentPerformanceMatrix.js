import { useQuery } from "@tanstack/react-query";
import * as studentAPI from "../../../api/studentAPI.js";

export function useStudentPerformanceMatrix(studentId) {
  return useQuery({
    queryKey: ["students", "performance-matrix", studentId],
    queryFn: () => studentAPI.getStudentPerformanceMatrix(studentId),
  });
}
