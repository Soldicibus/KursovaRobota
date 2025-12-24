import { getClassAbsentReport } from "../../../api/classesAPI.js";
import { useQuery } from "@tanstack/react-query";

export function useClassAbsent(className, amount) {
  return useQuery({
    queryKey: ["classAbsentReport", className, amount],
    queryFn: () => getClassAbsentReport(className, amount),
  });
};
export default useClassAbsent;