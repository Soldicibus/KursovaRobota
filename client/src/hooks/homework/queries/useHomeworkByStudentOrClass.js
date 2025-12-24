import { useQuery } from "@tanstack/react-query";
import * as homeworkAPI from "../../../api/homeworkAPI.js";

export function useHomeworkByStudentOrClass(studentId) {
  return useQuery({
    queryKey: ["homework", "by-student-or-class", studentId],
    queryFn: () => homeworkAPI.getHomeworkByStudentOrClass(studentId),
    enabled: !!studentId,
  });
}