import { useQuery } from "@tanstack/react-query";
import * as studentAPI from "../../../api/studentAPI.js";

export function useStudentMonthlyMarks(studentId, month) {
  return useQuery({
    queryKey: ["students", "monthly-marks", studentId, month],
    queryFn: () => studentAPI.getStudentMonthlyMarks(studentId, month),
    enabled: !!studentId,
  });
}
