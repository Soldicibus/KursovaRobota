import { useQuery } from "@tanstack/react-query";
import * as timetablesAPI from "../../../api/timetablesAPI.js";

export function useTimetables() {
  return useQuery({
    queryKey: ["timetables"],
    queryFn: timetablesAPI.getAllTimetables,
  });
}