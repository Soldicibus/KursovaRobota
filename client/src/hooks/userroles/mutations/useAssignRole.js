import { useMutation, useQueryClient } from "@tanstack/react-query";
import * as userroleAPI from "../../../api/userroleAPI.js";

export function useAssignRole() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: ({ userId, roleId }) => userroleAPI.assignRole(userId, roleId),
    onSuccess: () => qc.invalidateQueries({ queryKey: ["user-roles"] }),
  });
}