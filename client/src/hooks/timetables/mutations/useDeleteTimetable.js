import { useMutation, useQueryClient } from "@tanstack/react-query";
import * as timetablesAPI from "../../../api/timetablesAPI.js";

export function useDeleteTimetable() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: timetablesAPI.deleteTimetable,
    onSuccess: () => qc.invalidateQueries({ queryKey: ["timetables"] }),
  });
}