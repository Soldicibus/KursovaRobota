import { useQuery } from "@tanstack/react-query";
import * as studentAPI from "../../../api/studentAPI.js";

export function useStudentByClass() {
  return useQuery({
    queryKey: ["students", "by-class"],
    queryFn: studentAPI.getStudentByClass,
  });
}