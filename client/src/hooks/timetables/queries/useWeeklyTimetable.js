import { useQuery } from "@tanstack/react-query";
import * as timetablesAPI from "../../../api/timetablesAPI.js";

export function useWeeklyTimetable(id) {
  return useQuery({
    queryKey: ["timetable", "week", id],
    queryFn: () => timetablesAPI.getWeeklyTimetable(id),
    enabled: !!id,
  });
}