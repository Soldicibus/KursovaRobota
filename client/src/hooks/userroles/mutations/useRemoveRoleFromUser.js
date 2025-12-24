import { useMutation, useQueryClient } from "@tanstack/react-query";
import * as userroleAPI from "../../../api/userroleAPI.js";

export function useRemoveRoleFromUser() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: ({ userId, roleId }) => userroleAPI.removeRoleFromUser(userId, roleId),
    onSuccess: () => qc.invalidateQueries({ queryKey: ["user-roles"] }),
  });
}