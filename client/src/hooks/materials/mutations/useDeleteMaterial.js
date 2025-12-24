import { useMutation, useQueryClient } from "@tanstack/react-query";
import * as materialsAPI from "../../../api/materialsAPI.js";

export function useDeleteMaterial() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: materialsAPI.deleteMaterial,
    onSuccess: () => qc.invalidateQueries({ queryKey: ["materials"] }),
  });
}