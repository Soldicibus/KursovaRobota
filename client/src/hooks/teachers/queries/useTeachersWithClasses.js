import { useQuery } from "@tanstack/react-query";
import * as teacherAPI from "../../../api/teacherAPI.js";

export function useTeachersWithClasses(id) {
  return useQuery({
    queryKey: ["teachers", "with-classes", id],
    queryFn: () => teacherAPI.getTeachersWithClasses(id),
    enabled: !!id,
  });
}