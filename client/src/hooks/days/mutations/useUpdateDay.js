import { useMutation, useQueryClient } from "@tanstack/react-query";
import * as daysAPI from "../../../api/daysAPI.js";

export function useUpdateDay() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: daysAPI.updateDay,
    onSuccess: () => qc.invalidateQueries({ queryKey: ["days"] }),
  });
}