import { useMutation, useQueryClient } from "@tanstack/react-query";
import * as classesAPI from "../../../api/classesAPI.js";

export function useCreateClass() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: classesAPI.createClass,
    onSuccess: () => qc.invalidateQueries({ queryKey: ["classes"] }),
  });
}