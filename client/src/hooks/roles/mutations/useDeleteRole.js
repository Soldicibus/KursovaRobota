import { useMutation, useQueryClient } from "@tanstack/react-query";
import * as rolesAPI from "../../../api/rolesAPI.js";

export function useDeleteRole() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: rolesAPI.deleteRole,
    onSuccess: () => qc.invalidateQueries({ queryKey: ["roles"] }),
  });
}