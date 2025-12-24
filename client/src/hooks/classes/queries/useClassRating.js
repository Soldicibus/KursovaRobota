import { useQuery } from "@tanstack/react-query";
import * as classesAPI from "../../../api/classesAPI.js";

export function useClassRating() {
  return useQuery({
    // Use a distinct key namespace to avoid collisions with individual class lookups:
    // useClass(name) uses ["class", name].
    queryKey: ["classes", "rating"],
    queryFn: () => classesAPI.getClassRatingReport(),
  });
}