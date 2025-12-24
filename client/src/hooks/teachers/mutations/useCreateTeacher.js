import { useMutation, useQueryClient } from "@tanstack/react-query";
import * as teacherAPI from "../../../api/teacherAPI.js";

export function useCreateTeacher() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: teacherAPI.createTeacher,
    onSuccess: () => qc.invalidateQueries({ queryKey: ["teachers"] }),
  });
}