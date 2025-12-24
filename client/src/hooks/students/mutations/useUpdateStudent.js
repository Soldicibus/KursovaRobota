import { useMutation, useQueryClient } from "@tanstack/react-query";
import * as studentAPI from "../../../api/studentAPI.js";

export function useUpdateStudent() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: studentAPI.patchStudent,
    onSuccess: () => qc.invalidateQueries({ queryKey: ["students"] }),
  });
}