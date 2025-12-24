import { useMutation, useQueryClient } from "@tanstack/react-query";
import * as journalsAPI from "../../../api/journalsAPI.js";

export function useDeleteJournal() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: journalsAPI.deleteJournal,
    onSuccess: () => qc.invalidateQueries({ queryKey: ["journals"] }),
  });
}