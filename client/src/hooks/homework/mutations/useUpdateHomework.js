import { useMutation, useQueryClient } from "@tanstack/react-query";
import * as homeworkAPI from "../../../api/homeworkAPI.js";

export function useUpdateHomework() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: homeworkAPI.updateHomework,
    onSuccess: () => qc.invalidateQueries({ queryKey: ["homework"] }),
  });
}