import { useQuery } from "@tanstack/react-query";
import * as classesAPI from "../../../api/classesAPI.js";

export function useClass(name) {
  return useQuery({
    queryKey: ["class", name],
    queryFn: () => classesAPI.getClassByName(name),
    enabled: !!name,
  });
}