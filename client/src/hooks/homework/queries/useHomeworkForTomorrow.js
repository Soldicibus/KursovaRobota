import { useQuery } from "@tanstack/react-query";
import * as homeworkAPI from "../../../api/homeworkAPI.js";

export function useHomeworkForTomorrow() {
  return useQuery({
    queryKey: ["homework", "for-tomorrow"],
    queryFn: homeworkAPI.getHomeworkForTomorrow,
  });
}