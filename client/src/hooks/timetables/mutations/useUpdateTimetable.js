import { useMutation, useQueryClient } from "@tanstack/react-query";
import * as timetablesAPI from "../../../api/timetablesAPI.js";

export function useUpdateTimetable() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: timetablesAPI.updateTimetable,
    onSuccess: () => qc.invalidateQueries({ queryKey: ["timetables"] }),
  });
}