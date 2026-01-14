import { useQuery } from "@tanstack/react-query";
import * as lessonsAPI from "../../../api/lessonsAPI.js";

export function useLessonsByTeacher(teacherId) {
  return useQuery({
    queryKey: ["lessons", teacherId],
    queryFn: () => lessonsAPI.getLessonsByTeacher(teacherId),
    enabled: !!teacherId,
  });
}