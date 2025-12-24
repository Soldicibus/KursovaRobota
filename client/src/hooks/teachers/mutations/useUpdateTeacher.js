import { useMutation, useQueryClient } from "@tanstack/react-query";
import * as teacherAPI from "../../../api/teacherAPI.js";

export function useUpdateTeacher() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: teacherAPI.patchTeacher,
    onSuccess: () => qc.invalidateQueries({ queryKey: ["teachers"] }),
  });
}