import { useQuery } from "@tanstack/react-query";
import * as materialsAPI from "../../../api/materialsAPI.js";

export function useMaterials() {
  return useQuery({
    queryKey: ["materials"],
    queryFn: materialsAPI.getAllMaterials,
  });
}