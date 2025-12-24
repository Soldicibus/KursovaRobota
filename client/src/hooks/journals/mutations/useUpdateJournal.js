import { useMutation, useQueryClient } from "@tanstack/react-query";
import * as journalsAPI from "../../../api/journalsAPI.js";

export function useUpdateJournal() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: journalsAPI.updateJournal,
    onSuccess: () => qc.invalidateQueries({ queryKey: ["journals"] }),
  });
}