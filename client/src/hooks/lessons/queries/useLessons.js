import { useQuery } from "@tanstack/react-query";
import * as lessonsAPI from "../../../api/lessonsAPI.js";

export function useLessons() {
  return useQuery({
    queryKey: ["lessons"],
    queryFn: lessonsAPI.getAllLessons,
  });
}