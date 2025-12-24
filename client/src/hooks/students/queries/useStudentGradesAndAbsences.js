import { useQuery } from "@tanstack/react-query";
import * as studentAPI from "../../../api/studentAPI.js";

export function useStudentGradesAndAbsences(id) {
  return useQuery({
    queryKey: ["students", "grades-absences", id],
    queryFn: () => studentAPI.getGradesAndAbsences(id),
  });
}