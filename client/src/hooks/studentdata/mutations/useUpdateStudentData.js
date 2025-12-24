import { useMutation, useQueryClient } from "@tanstack/react-query";
import * as studentdataAPI from "../../../api/studentdataAPI.js";

export function useUpdateStudentData() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: studentdataAPI.updateStudentData,
    onSuccess: () => qc.invalidateQueries({ queryKey: ["studentdata"] }),
  });
}