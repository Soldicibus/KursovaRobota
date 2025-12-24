import { useQuery } from "@tanstack/react-query";
import * as teacherAPI from "../../../api/teacherAPI.js";

export function useTeacherWithClassesName(className) {
  return useQuery({
    queryKey: ["teachers", "with-classes-by-name", className],
    // Pass through raw route/className; API layer handles decode+encode.
    queryFn: () => teacherAPI.getTeachersWithClassesByName(className),
    enabled: !!className,
  });
}