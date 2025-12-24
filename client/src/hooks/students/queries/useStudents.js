import { useQuery } from "@tanstack/react-query";
import * as studentAPI from "../../../api/studentAPI.js";

export function useStudents() {
  return useQuery({
    queryKey: ["students"],
    queryFn: studentAPI.getAllStudents,
  });
}