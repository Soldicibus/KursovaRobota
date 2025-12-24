import { useQuery } from "@tanstack/react-query";
import * as daysAPI from "../../../api/daysAPI.js";

export function useDay(id) {
  return useQuery({
    queryKey: ["day", id],
    queryFn: () => daysAPI.getDayById(id),
    enabled: !!id,
  });
}