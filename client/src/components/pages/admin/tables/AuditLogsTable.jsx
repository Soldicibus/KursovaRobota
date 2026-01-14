import React, { useMemo } from 'react';
import DataTable from '../../../common/DataTable';
import { useAuditLogs } from '../../../../hooks/auditlogs/queries/useAuditLogs';
import { useAdminPermissions } from '../../../../hooks/useAdminPermissions';

export default function AuditLogsTable() {
  const { data: auditData, isLoading } = useAuditLogs();
  const { isSAdmin } = useAdminPermissions();

  const columns = useMemo(
    () => [
      { header: 'ID', accessor: 'log_id' },
      { header: 'Table', accessor: 'table_name' },
      { header: 'Operation', accessor: 'operation' },
      { header: 'Record ID', accessor: 'record_id' },
      { header: 'Changed By', accessor: 'changed_by' },
      { header: 'Username', accessor: 'username' },
      { 
        header: 'Changed At', 
        accessor: 'changed_at', 
        render: (row) => new Date(row.changed_at).toLocaleString() 
      },
      { header: 'Details', accessor: 'details' },
    ],
    []
  );

  if (!isSAdmin) {
    return <div className="p-4 text-red-500">Access Restricted: Only SuperAdmins can view audit logs.</div>;
  }

  return (
    <DataTable
      title="System Audit Logs"
      data={auditData || []}
      columns={columns}
      isLoading={isLoading}
      canCreate={false}
      canEdit={false}
      canDelete={false}
    />
  );
}
