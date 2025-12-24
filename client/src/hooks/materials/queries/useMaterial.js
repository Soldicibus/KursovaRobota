import { useQuery } from "@tanstack/react-query";
import * as materialsAPI from "../../../api/materialsAPI.js";

export function useMaterial(id) {
  return useQuery({
    queryKey: ["material", id],
    queryFn: () => materialsAPI.getMaterialById(id),
    enabled: !!id,
  });
}