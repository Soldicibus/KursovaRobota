import { useMutation, useQueryClient } from "@tanstack/react-query";
import * as lessonsAPI from "../../../api/lessonsAPI.js";

export function useDeleteLesson() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: lessonsAPI.deleteLesson,
    onSuccess: () => qc.invalidateQueries({ queryKey: ["lessons"] }),
  });
}