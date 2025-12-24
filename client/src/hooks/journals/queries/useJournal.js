import { useQuery } from "@tanstack/react-query";
import * as journalsAPI from "../../../api/journalsAPI.js";

export function useJournal(id) {
  return useQuery({
    queryKey: ["journal", id],
    queryFn: () => journalsAPI.getJournalById(id),
    enabled: !!id,
  });
}