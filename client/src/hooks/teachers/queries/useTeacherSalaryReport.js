import { useQuery } from "@tanstack/react-query";
import * as teacherAPI from "../../../api/teacherAPI.js";

export function useTeacherSalaryReport(id, fromDate, toDate, options = {}) {
  return useQuery({
    queryKey: ["teachers", "salary-report", id, fromDate, toDate],
    queryFn: () => teacherAPI.getTeacherSalaryReport(id, fromDate, toDate),
    ...options
  });
}