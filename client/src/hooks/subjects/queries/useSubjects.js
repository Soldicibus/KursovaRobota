import { useQuery } from "@tanstack/react-query";
import * as subjectsAPI from "../../../api/subjectsAPI.js";

export function useSubjects() {
  return useQuery({
    queryKey: ["subjects"],
    queryFn: subjectsAPI.getAllSubjects,
  });
}