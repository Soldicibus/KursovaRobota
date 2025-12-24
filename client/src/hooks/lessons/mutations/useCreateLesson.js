import { useMutation, useQueryClient } from "@tanstack/react-query";
import * as lessonsAPI from "../../../api/lessonsAPI.js";

export function useCreateLesson() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: lessonsAPI.createLesson,
    onSuccess: () => qc.invalidateQueries({ queryKey: ["lessons"] }),
  });
}