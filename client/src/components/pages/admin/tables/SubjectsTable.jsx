import React, { useState } from 'react';
import DataTable from '../../../common/DataTable';
import { useSubjects } from '../../../../hooks/subjects/queries/useSubjects';
import { useCreateSubject } from '../../../../hooks/subjects/mutations/useCreateSubject';
import { useDeleteSubject } from '../../../../hooks/subjects/mutations/useDeleteSubject';
import { useAdminPermissions } from '../../../../hooks/useAdminPermissions';
import Modal from '../../../common/Modal';

export default function SubjectsTable() {
  const { data: subjects, isLoading } = useSubjects();
  const { permissions } = useAdminPermissions();

  const createMutation = useCreateSubject();
  const deleteMutation = useDeleteSubject();

  const [isModalOpen, setIsModalOpen] = useState(false);
  const [formData, setFormData] = useState({ name: '', program: '' });

  const handleDelete = async (item) => {
    if (window.confirm(`Delete subject ${item.subject_name}?`)) {
      try {
        await deleteMutation.mutateAsync(item.subject_id);
      } catch (error) {
        alert('Error deleting subject: ' + error.message);
      }
    }
  };

  const handleCreate = () => {
    setFormData({ name: '', program: '' });
    setIsModalOpen(true);
  };

  const handleSubmit = async (e) => {
    e.preventDefault();
    try {
      await createMutation.mutateAsync(formData);
      setIsModalOpen(false);
    } catch (error) {
      alert('Error: ' + error.message);
    }
  };

  const columns = [
    { header: 'ID', accessor: 'subject_id' },
    { header: 'Name', accessor: 'subject_name' },
    { header: 'Program', accessor: 'subject_program' },
  ];

  return (
    <>
      <DataTable
        title="Subjects"
        data={subjects?.slice().sort((a, b) => a.subject_id - b.subject_id)}
        columns={columns}
        isLoading={isLoading}
        onDelete={handleDelete}
        onCreate={handleCreate}
        canEdit={false}
        canDelete={permissions.others.delete}
        canCreate={permissions.others.create}
      />

      <Modal
        isOpen={isModalOpen}
        onClose={() => setIsModalOpen(false)}
        title="Create Subject"
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
            <label className="block text-sm font-medium text-gray-700">Program</label>
            <textarea
              value={formData.program}
              onChange={(e) => setFormData({ ...formData, program: e.target.value })}
              className="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-indigo-500 focus:ring-indigo-500 sm:text-sm text-gray-900"
            />
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
              Create
            </button>
          </div>
        </form>
      </Modal>
    </>
  );
}
