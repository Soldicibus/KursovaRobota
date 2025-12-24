import React, { useState } from 'react';
import DataTable from '../../../common/DataTable';
import { useJournals } from '../../../../hooks/journals/queries/useJournals';
import { useCreateJournal } from '../../../../hooks/journals/mutations/useCreateJournal';
import { useUpdateJournal } from '../../../../hooks/journals/mutations/useUpdateJournal';
import { useDeleteJournal } from '../../../../hooks/journals/mutations/useDeleteJournal';
import { useTeachers } from '../../../../hooks/teachers/queries/useTeachers';
import { useAdminPermissions } from '../../../../hooks/useAdminPermissions';
import Modal from '../../../common/Modal';

export default function JournalsTable() {
  const { data: journals, isLoading } = useJournals();
  const { permissions } = useAdminPermissions();

  const createMutation = useCreateJournal();
  const updateMutation = useUpdateJournal();
  const deleteMutation = useDeleteJournal();

  const { data: teachers } = useTeachers();

  const [isModalOpen, setIsModalOpen] = useState(false);
  const [editingJournal, setEditingJournal] = useState(null);
  const [formData, setFormData] = useState({ name: '', teacherId: '' });

  const handleEdit = (item) => {
    setEditingJournal(item);
    setFormData({
      name: item.journal_name || '',
      teacherId: item.journal_teacher || ''
    });
    setIsModalOpen(true);
  };

  const handleDelete = async (item) => {
    if (window.confirm(`Delete journal ${item.journal_name}?`)) {
      try {
        await deleteMutation.mutateAsync(item.journal_id);
      } catch (error) {
        alert('Error deleting journal: ' + error.message);
      }
    }
  };

  const handleCreate = () => {
    setEditingJournal(null);
    setFormData({ name: '', teacherId: '' });
    setIsModalOpen(true);
  };

  const handleSubmit = async (e) => {
    e.preventDefault();
    try {
      if (editingJournal) {
        await updateMutation.mutateAsync({
          id: editingJournal.journal_id,
          ...formData
        });
      } else {
        await createMutation.mutateAsync(formData);
      }
      setIsModalOpen(false);
    } catch (error) {
      alert('Error: ' + error.message);
    }
  };

  const columns = [
    { header: 'ID', accessor: 'journal_id' },
    { header: 'Name', accessor: 'journal_name' },
    { header: 'Teacher ID', accessor: 'journal_teacher' },
  ];

  return (
    <>
      <DataTable
        title="Journals"
        data={journals?.slice().sort((a, b) => a.journal_id - b.journal_id)}
        columns={columns}
        isLoading={isLoading}
        onEdit={handleEdit}
        onDelete={handleDelete}
        onCreate={handleCreate}
        canEdit={permissions.others.edit}
        canDelete={permissions.others.delete}
        canCreate={permissions.others.create}
      />

      <Modal
        isOpen={isModalOpen}
        onClose={() => setIsModalOpen(false)}
        title={editingJournal ? 'Edit Journal' : 'Create Journal'}
      >
        <form onSubmit={handleSubmit} className="space-y-4">
          <div>
            <label className="block text-sm font-medium text-gray-700">Name</label>
            <input
              type="text"
              value={formData.name}
              onChange={(e) => setFormData({ ...formData, name: e.target.value })}
              className="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-indigo-500 focus:ring-indigo-500 sm:text-sm text-gray-900"
              required
            />
          </div>
          <div>
            <label className="block text-sm font-medium text-gray-700">Teacher</label>
            <select
              value={formData.teacherId}
              onChange={(e) => setFormData({ ...formData, teacherId: e.target.value })}
              className="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-indigo-500 focus:ring-indigo-500 sm:text-sm text-gray-900"
              required
            >
              <option value="">Select Teacher</option>
              {teachers?.map((t) => (
                <option key={t.teacher_id} value={t.teacher_id}>
                  {t.teacher_name} {t.teacher_surname}
                </option>
              ))}
            </select>
          </div>
          <div className="flex justify-end space-x-3 pt-4">
            <button
              type="button"
              onClick={() => setIsModalOpen(false)}
              className="rounded-md border border-gray-300 bg-white px-4 py-2 text-sm font-medium text-gray-700 shadow-sm hover:bg-gray-50 focus:outline-none focus:ring-2 focus:ring-indigo-500 focus:ring-offset-2"
            >
              Cancel
            </button>
            <button
              type="submit"
              className="rounded-md border border-transparent bg-indigo-600 px-4 py-2 text-sm font-medium text-white shadow-sm hover:bg-indigo-700 focus:outline-none focus:ring-2 focus:ring-indigo-500 focus:ring-offset-2"
            >
              {editingJournal ? 'Update' : 'Create'}
            </button>
          </div>
        </form>
      </Modal>
    </>
  );
}
