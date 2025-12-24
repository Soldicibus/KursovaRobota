import { useMutation, useQueryClient } from "@tanstack/react-query";
import * as classesAPI from "../../../api/classesAPI.js";

export function useDeleteClass() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: classesAPI.deleteClass,
    onSuccess: () => qc.invalidateQueries({ queryKey: ["classes"] }),
  });
}