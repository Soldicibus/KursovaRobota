import { useMutation, useQueryClient } from "@tanstack/react-query";
import * as materialsAPI from "../../../api/materialsAPI.js";

export function useCreateMaterial() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: materialsAPI.createMaterial,
    onSuccess: () => qc.invalidateQueries({ queryKey: ["materials"] }),
  });
}