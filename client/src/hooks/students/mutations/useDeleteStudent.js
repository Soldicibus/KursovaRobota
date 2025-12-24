import { useMutation, useQueryClient } from "@tanstack/react-query";
import * as studentAPI from "../../../api/studentAPI.js";

export function useDeleteStudent() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: studentAPI.deleteStudent,
    onSuccess: () => qc.invalidateQueries({ queryKey: ["students"] }),
  });
}