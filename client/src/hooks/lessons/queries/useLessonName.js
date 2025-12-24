import { useQuery } from "@tanstack/react-query";
import * as lessonsAPI from "../../../api/lessonsAPI.js";

export function useLessonName(name) {
  return useQuery({
    queryKey: ["lesson", name],
    queryFn: () => lessonsAPI.getLessonByName(name),
    enabled: !!name,
  });
}