import { useQuery } from "@tanstack/react-query";
import * as studentdataAPI from "../../../api/studentdataAPI.js";

export function useStudentData() {
  return useQuery({
    queryKey: ["studentdata"],
    queryFn: studentdataAPI.getAllStudentData,
  });
}