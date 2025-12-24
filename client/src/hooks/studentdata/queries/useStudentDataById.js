import { useQuery } from "@tanstack/react-query";
import * as studentdataAPI from "../../../api/studentdataAPI.js";

export function useStudentDataById(id) {
  return useQuery({
    queryKey: ["studentdata", id],
    queryFn: () => studentdataAPI.getStudentDataById(id),
    enabled: !!id,
  });
}