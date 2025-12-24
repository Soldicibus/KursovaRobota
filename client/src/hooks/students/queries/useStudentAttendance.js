import { useQuery } from "@tanstack/react-query";
import * as studentAPI from "../../../api/studentAPI.js";

export function useStudentAttendance(id) {
  return useQuery({
    queryKey: ["students", "attendance", id],
    queryFn: () => studentAPI.getStudentsAttendance(id),
    enabled: !!id,
  });
}

// Backwards-compatible name used by some pages
export const useStudentAttendanceReport = (id) => useStudentAttendance(id);