import { useMutation, useQueryClient } from "@tanstack/react-query";
import * as teacherAPI from "../../../api/teacherAPI.js";

export function useDeleteTeacher() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: teacherAPI.deleteTeacher,
    onSuccess: () => qc.invalidateQueries({ queryKey: ["teachers"] }),
  });
}