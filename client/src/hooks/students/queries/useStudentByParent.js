import { useQuery } from "@tanstack/react-query";
import * as studentAPI from "../../../api/studentAPI.js";

export function useStudentsByParent(parentId) {
  return useQuery({
    queryKey: ["students", "by-parent", parentId],
    queryFn: () => studentAPI.getStudentByParentId(parentId),
    enabled: !!parentId,
  });
}