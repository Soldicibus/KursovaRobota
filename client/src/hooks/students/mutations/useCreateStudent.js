import { useMutation, useQueryClient } from "@tanstack/react-query";
import * as studentAPI from "../../../api/studentAPI.js";

export function useCreateStudent() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: studentAPI.createStudent,
    onSuccess: () => qc.invalidateQueries({ queryKey: ["students"] }),
  });
}