import { useMutation, useQueryClient } from "@tanstack/react-query";
import * as homeworkAPI from "../../../api/homeworkAPI.js";

export function useDeleteHomework() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: homeworkAPI.deleteHomework,
    onSuccess: () => qc.invalidateQueries({ queryKey: ["homework"] }),
  });
}