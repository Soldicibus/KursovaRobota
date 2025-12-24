import { useMutation, useQueryClient } from "@tanstack/react-query";
import * as daysAPI from "../../../api/daysAPI.js";

export function useCreateDay() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: daysAPI.createDay,
    onSuccess: () => qc.invalidateQueries({ queryKey: ["days"] }),
  });
}