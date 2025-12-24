import { useQuery } from "@tanstack/react-query";
import * as studentdataAPI from "../../../api/studentdataAPI.js";

export function useStudentDataMarks7d(studentId) {
  return useQuery({
    queryKey: ["studentdata", "marks-7d", studentId],
    queryFn: () => studentdataAPI.getStudentDataMarks7d(studentId),
    enabled: !!studentId,
  });
}