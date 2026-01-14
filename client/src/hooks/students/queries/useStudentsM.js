import {useQuery} from "@tanstack/react-query";
import {getAllStudentsM} from "../../../api/studentAPI";

export function useStudentsM() {
  return useQuery({
    queryKey: ["students", "m"],
    queryFn: getAllStudentsM,
  });
}