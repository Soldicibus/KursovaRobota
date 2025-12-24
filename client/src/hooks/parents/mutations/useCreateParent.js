import { useMutation, useQueryClient } from "@tanstack/react-query";
import * as parentAPI from "../../../api/parentAPI.js";

export function useCreateParent() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: parentAPI.createParent,
    onSuccess: () => qc.invalidateQueries({ queryKey: ["parents"] }),
  });
}