import { useQuery } from "@tanstack/react-query";
import * as timetablesAPI from "../../../api/timetablesAPI.js";

export function useTimetableByStudent(studentId) {
  return useQuery({
    queryKey: ["timetable", "by-student", studentId],
    queryFn: () => timetablesAPI.getTimetableByStudentId(studentId),
    enabled: !!studentId,
  });
}