import { useQuery } from "@tanstack/react-query";
import * as journalsAPI from "../../../api/journalsAPI.js";

export function useJournalByStudent(studentId) {
  return useQuery({
    queryKey: ["journal", "by-student", studentId],
    queryFn: () => journalsAPI.getJournalByStudent(studentId),
    enabled: !!studentId,
  });
}