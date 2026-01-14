import { useQuery } from '@tanstack/react-query';
import { getAuditLogs } from '../../../api/auditlogs';

export const useAuditLogs = () => {
  return useQuery({
    queryKey: ['auditlogs'],
    queryFn: getAuditLogs,
  });
};
