import { useQuery } from "@tanstack/react-query";
import * as teacherAPI from "../../../api/teacherAPI.js";

export function useTeachers() {
  return useQuery({
    queryKey: ["teachers"],
    queryFn: teacherAPI.getTeachers,
  });
}