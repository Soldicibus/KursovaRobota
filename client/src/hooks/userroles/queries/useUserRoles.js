import { useQuery } from "@tanstack/react-query";
import * as userroleAPI from "../../../api/userroleAPI.js";

export function useUserRoles() {
  return useQuery({
    queryKey: ["user-roles"],
    queryFn: () => userroleAPI.getUserRoles(),
  });
}