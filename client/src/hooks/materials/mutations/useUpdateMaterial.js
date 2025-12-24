import { useMutation, useQueryClient } from "@tanstack/react-query";
import * as materialsAPI from "../../../api/materialsAPI.js";

export function useUpdateMaterial() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: materialsAPI.updateMaterial,
    onSuccess: () => qc.invalidateQueries({ queryKey: ["materials"] }),
  });
}