import { useMutation, useQueryClient } from "@tanstack/react-query";
import * as homeworkAPI from "../../../api/homeworkAPI.js";

export function useCreateHomework() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: homeworkAPI.createHomework,
    onSuccess: () => qc.invalidateQueries({ queryKey: ["homework"] }),
  });
}