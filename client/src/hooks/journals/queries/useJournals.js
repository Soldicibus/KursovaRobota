import { useQuery } from "@tanstack/react-query";
import * as journalsAPI from "../../../api/journalsAPI.js";

export function useJournals() {
  return useQuery({
    queryKey: ["journals"],
    queryFn: journalsAPI.getAllJournals,
  });
}