import { useMutation, useQueryClient } from "@tanstack/react-query";
import * as parentAPI from "../../../api/parentAPI.js";

export function useUpdateParent() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: parentAPI.patchParent,
    onSuccess: () => qc.invalidateQueries({ queryKey: ["parents"] }),
  });
}