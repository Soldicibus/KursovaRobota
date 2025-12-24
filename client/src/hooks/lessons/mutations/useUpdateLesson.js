import { useMutation, useQueryClient } from "@tanstack/react-query";
import * as lessonsAPI from "../../../api/lessonsAPI.js";

export function useUpdateLesson() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: lessonsAPI.updateLesson,
    onSuccess: () => qc.invalidateQueries({ queryKey: ["lessons"] }),
  });
}