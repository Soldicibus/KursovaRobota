import { useQuery } from "@tanstack/react-query";
import * as lessonsAPI from "../../../api/lessonsAPI.js";

export function useLessonsByTeacherAndName(teacherId, name) {
  return useQuery({
    queryKey: ["lessons", teacherId, name],
    queryFn: () => lessonsAPI.getLessonsByTeacherAndName(teacherId, name),
    enabled: !!teacherId && !!name,
  });
}
