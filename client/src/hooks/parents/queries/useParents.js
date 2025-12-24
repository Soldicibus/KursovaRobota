import { useQuery } from "@tanstack/react-query";
import * as parentAPI from "../../../api/parentAPI.js";

export function useParents() {
  return useQuery({
    queryKey: ["parents"],
    queryFn: parentAPI.getParents,
  });
}