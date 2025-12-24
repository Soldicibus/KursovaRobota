import { useQuery } from "@tanstack/react-query";
import * as studentAPI from "../../../api/studentAPI.js";

export function useStudentAVGAbove7() {
  return useQuery({
    queryKey: ["students", "avg-above-7"],
    queryFn: studentAPI.getStudentAVGAbove7,
  });
}