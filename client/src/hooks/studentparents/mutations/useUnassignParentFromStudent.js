import { useMutation, useQueryClient } from "@tanstack/react-query";
import * as studentparentsAPI from "../../../api/studentparentsAPI.js";

export function useUnassignParentFromStudent() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: studentparentsAPI.unassignParentFromStudent,
    onSuccess: () => qc.invalidateQueries({ queryKey: ["studentparents"] }),
  });
}