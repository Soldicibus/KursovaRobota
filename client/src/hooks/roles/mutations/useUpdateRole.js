import { useMutation, useQueryClient } from "@tanstack/react-query";
import * as rolesAPI from "../../../api/rolesAPI.js";

export function useUpdateRole() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: rolesAPI.updateRole,
    onSuccess: () => qc.invalidateQueries({ queryKey: ["roles"] }),
  });
}