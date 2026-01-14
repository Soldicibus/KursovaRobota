import { useMutation, useQueryClient } from "@tanstack/react-query";
import * as studentAPI from "../../../api/studentAPI.js";

export function useCreateStudent() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: (variables) => {
      if (variables.user_id) {
        return studentAPI.createStudentWithUser(variables);
      }
      return studentAPI.createStudent(variables);
    },
    onSuccess: () => qc.invalidateQueries({ queryKey: ["students"] }),
  });
}