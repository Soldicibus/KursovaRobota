import { useMutation, useQueryClient } from "@tanstack/react-query";
import * as daysAPI from "../../../api/daysAPI.js";

export function useDeleteDay() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: daysAPI.deleteDay,
    onSuccess: () => qc.invalidateQueries({ queryKey: ["days"] }),
  });
}