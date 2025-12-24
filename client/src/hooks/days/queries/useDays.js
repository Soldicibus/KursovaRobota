import { useQuery } from "@tanstack/react-query";
import * as daysAPI from "../../../api/daysAPI.js";

export function useDays() {
  return useQuery({
    queryKey: ["days"],
    queryFn: daysAPI.getAllDays,
  });
}