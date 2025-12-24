import { useMutation, useQueryClient } from "@tanstack/react-query";
import * as parentAPI from "../../../api/parentAPI.js";

export function useDeleteParent() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: parentAPI.deleteParent,
    onSuccess: () => qc.invalidateQueries({ queryKey: ["parents"] }),
  });
}