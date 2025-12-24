import { useMutation, useQueryClient } from "@tanstack/react-query";
import * as subjectsAPI from "../../../api/subjectsAPI.js";

export function useCreateSubject() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: subjectsAPI.createSubject,
    onSuccess: () => qc.invalidateQueries({ queryKey: ["subjects"] }),
  });
}