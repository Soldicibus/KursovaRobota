import { useQuery } from "@tanstack/react-query";
import * as classesAPI from "../../../api/classesAPI.js";

export function useClasses() {
  return useQuery({
    queryKey: ["classes"],
    queryFn: classesAPI.getAllClasses,
  });
}