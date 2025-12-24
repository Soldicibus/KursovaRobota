import { useQuery } from "@tanstack/react-query";
import * as studentAPI from "../../../api/studentAPI.js";

export function useStudentDayPlan() {
  return useQuery({
    queryKey: ["students", "day-plan"],
    queryFn: studentAPI.getStudentsDayPlan,
  });
}