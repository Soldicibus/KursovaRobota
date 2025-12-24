import { useQuery } from "@tanstack/react-query";
import * as homeworkAPI from "../../../api/homeworkAPI.js";

export function useHomework() {
  return useQuery({
    queryKey: ["homework"],
    queryFn: homeworkAPI.getAllHomework,
  });
}