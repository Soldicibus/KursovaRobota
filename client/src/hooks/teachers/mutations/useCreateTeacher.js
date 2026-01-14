import { useMutation, useQueryClient } from "@tanstack/react-query";
import * as teacherAPI from "../../../api/teacherAPI.js";

export function useCreateTeacher() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: (variables) => {
      if (variables.user_id) {
        return teacherAPI.createTeacherWithUser(variables);
      }
      return teacherAPI.createTeacher(variables);
    },
    onSuccess: () => qc.invalidateQueries({ queryKey: ["teachers"] }),
  });
}