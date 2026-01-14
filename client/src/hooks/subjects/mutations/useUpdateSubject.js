import { useMutation, useQueryClient } from "@tanstack/react-query";
import * as subjectsAPI from "../../../api/subjectsAPI.js";

export function useUpdateSubject() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: subjectsAPI.patchSubject,
    onSuccess: () => qc.invalidateQueries({ queryKey: ["subjects"] }),
  });
}
