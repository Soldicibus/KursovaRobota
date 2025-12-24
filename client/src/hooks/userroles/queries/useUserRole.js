import { useQuery } from "@tanstack/react-query";
import * as userroleAPI from "../../../api/userroleAPI.js";

export function useUserRole(userId) {
  return useQuery({
    queryKey: ["user-role", userId],
    queryFn: () => userroleAPI.getUserRole(userId),
    enabled: !!userId,
  });
}