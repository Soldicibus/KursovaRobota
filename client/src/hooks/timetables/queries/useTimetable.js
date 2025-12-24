import { useQuery } from "@tanstack/react-query";
import * as timetablesAPI from "../../../api/timetablesAPI.js";

export function useTimetable(id) {
  return useQuery({
    queryKey: ["timetable", id],
    queryFn: () => timetablesAPI.getTimetableById(id),
    enabled: !!id,
  });
}