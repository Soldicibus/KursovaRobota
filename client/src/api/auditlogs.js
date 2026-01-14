import api from './lib/api';

export const getAuditLogs = async () => {
  const response = await api.get('/auditlogs');
  return response.data.auditlogs;
};
