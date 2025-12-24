import { useQuery } from "@tanstack/react-query";
import * as lessonsAPI from "../../../api/lessonsAPI.js";

export function useLesson(id) {
  return useQuery({
    queryKey: ["lesson", id],
    queryFn: () => lessonsAPI.getLessonById(id),
    enabled: !!id,
  });
}