import { useQuery } from "@tanstack/react-query";
import * as studentAPI from "../../../api/studentAPI.js";

export function useStudentMarks() {
  return useQuery({
    queryKey: ["students", "marks"],
    queryFn: studentAPI.getStudentsMarks,
  });
}