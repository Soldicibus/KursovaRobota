import { useMutation, useQueryClient } from "@tanstack/react-query";
import * as classesAPI from "../../../api/classesAPI.js";

export function useUpdateClass() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: classesAPI.updateClass,
    onSuccess: () => qc.invalidateQueries({ queryKey: ["classes"] }),
  });
}