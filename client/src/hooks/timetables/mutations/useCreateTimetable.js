import { useMutation, useQueryClient } from "@tanstack/react-query";
import * as timetablesAPI from "../../../api/timetablesAPI.js";

export function useCreateTimetable() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: timetablesAPI.createTimetable,
    onSuccess: () => qc.invalidateQueries({ queryKey: ["timetables"] }),
  });
}