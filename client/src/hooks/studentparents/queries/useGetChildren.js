import { getChildren } from "../../../api/studentparentsAPI";
import { useQuery } from "@tanstack/react-query";

export function useGetChildren(parentId) {
  return useQuery({
    queryKey: ["studentparents", "children", parentId],
    queryFn: () => getChildren(parentId),
    enabled: !!parentId,
  });
}