import { useQuery } from "@tanstack/react-query";
import * as homeworkAPI from "../../../api/homeworkAPI.js";

export function useHomeworkById(id) {
  return useQuery({
    queryKey: ["homework", id],
    queryFn: () => homeworkAPI.getHomeworkById(id),
    enabled: !!id,
  });
}