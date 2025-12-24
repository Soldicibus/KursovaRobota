import { useQuery } from "@tanstack/react-query";
import * as parentAPI from "../../../api/parentAPI.js";

export function useParent(id) {
  return useQuery({
    queryKey: ["parent", id],
    queryFn: () => parentAPI.getParentById(id),
    enabled: !!id,
  });
}