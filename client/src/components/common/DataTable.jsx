import React from 'react';
import './DataTable.css';

export default function DataTable({ 
  data, 
  columns, 
  onEdit, 
  onDelete, 
  onCreate, 
  onResetPassword,
  title, 
  isLoading,
  canEdit = true,
  canDelete = true,
  canCreate = true,
  canResetPassword = false,
  extraAction = null,
}) {
  if (isLoading) return <div>Loading...</div>;

  return (
    <div className="data-table-container">
      <div className="data-table-header">
        <h2>{title}</h2>
        <div style={{ display: 'flex', gap: 8, alignItems: 'center' }}>
          {canCreate && onCreate && (
            <button className="btn btn-primary" onClick={onCreate}>Create New</button>
          )}
          {extraAction}
        </div>
      </div>
      <table className="data-table">
        <thead>
          <tr>
            {columns.map((col, index) => (
              <th key={index}>{col.header}</th>
            ))}
            {(canEdit || canDelete || canResetPassword) && <th>Actions</th>}
          </tr>
        </thead>
        <tbody>
          {data?.map((row, rowIndex) => (
            <tr 
              key={rowIndex} 
              onClick={() => canEdit && onEdit && onEdit(row)}
              style={{ cursor: canEdit && onEdit ? 'pointer' : 'default' }}
              className="data-table-row"
            >
              {columns.map((col, colIndex) => (
                <td key={colIndex}>
                  {col.render ? col.render(row) : row[col.accessor]}
                </td>
              ))}
              {(canEdit || canDelete || canResetPassword) && (
                <td className="actions-cell" onClick={(e) => e.stopPropagation()}>
                  {canEdit && onEdit && (
                    <button className="btn btn-small btn-edit" onClick={(e) => { e.stopPropagation(); onEdit(row); }}>Edit</button>
                  )}
                  {canResetPassword && onResetPassword && (
                    <button className="btn btn-small btn-warning" onClick={(e) => { e.stopPropagation(); onResetPassword(row); }}>Reset Pass</button>
                  )}
                  {canDelete && onDelete && (
                    <button className="btn btn-small btn-danger" onClick={(e) => { e.stopPropagation(); onDelete(row); }}>Delete</button>
                  )}
                </td>
              )}
            </tr>
          ))}
          {(!data || data.length === 0) && (
            <tr>
              <td colSpan={columns.length + 1} className="text-center">No data found</td>
            </tr>
          )}
        </tbody>
      </table>
    </div>
  );
}
