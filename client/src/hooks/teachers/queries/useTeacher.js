import { useQuery } from "@tanstack/react-query";
import * as teacherAPI from "../../../api/teacherAPI.js";

export function useTeacher(id) {
  return useQuery({
    queryKey: ["teacher", id],
    queryFn: () => teacherAPI.getTeacherById(id),
    enabled: !!id,
  });
}