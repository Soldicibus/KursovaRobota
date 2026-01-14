import { useMutation, useQueryClient } from "@tanstack/react-query";
import * as parentAPI from "../../../api/parentAPI.js";

export function useCreateParent() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: (variables) => {
      if (variables.user_id) {
        return parentAPI.createParentWithUser(variables);
      }
      return parentAPI.createParent(variables);
    },
    onSuccess: () => qc.invalidateQueries({ queryKey: ["parents"] }),
  });
}