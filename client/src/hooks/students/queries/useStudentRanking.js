import { useQuery } from "@tanstack/react-query";
import * as studentAPI from "../../../api/studentAPI.js";

export function useStudentRanking() {
  return useQuery({
    queryKey: ["students", "ranking"],
    queryFn: studentAPI.getStudentRanking,
  });
}