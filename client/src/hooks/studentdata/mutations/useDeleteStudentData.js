import { useMutation, useQueryClient } from "@tanstack/react-query";
import * as studentdataAPI from "../../../api/studentdataAPI.js";

export function useDeleteStudentData() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: studentdataAPI.deleteStudentData,
    onSuccess: () => qc.invalidateQueries({ queryKey: ["studentdata"] }),
  });
}