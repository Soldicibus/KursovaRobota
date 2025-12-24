import React, { useState } from 'react';
import DataTable from '../../../common/DataTable';
import { useClasses } from '../../../../hooks/classes/queries/useClasses';
import { useCreateClass } from '../../../../hooks/classes/mutations/useCreateClass';
import { useUpdateClass } from '../../../../hooks/classes/mutations/useUpdateClass';
import { useDeleteClass } from '../../../../hooks/classes/mutations/useDeleteClass';
import { useJournals } from '../../../../hooks/journals/queries/useJournals';
import { useTeachers } from '../../../../hooks/teachers/queries/useTeachers';
import { useAdminPermissions } from '../../../../hooks/useAdminPermissions';
import Modal from '../../../common/Modal';

export default function ClassesTable() {
  const { data: classes, isLoading } = useClasses();
  const { permissions } = useAdminPermissions();
  
  const createMutation = useCreateClass();
  const updateMutation = useUpdateClass();
  const deleteMutation = useDeleteClass();

  const { data: journals } = useJournals();
  const { data: teachers } = useTeachers();

  const [isModalOpen, setIsModalOpen] = useState(false);
  const [editingClass, setEditingClass] = useState(null);
  const [formData, setFormData] = useState({ name: '', journalId: '', mainTeacherId: '' });

  const handleEdit = (item) => {
    setEditingClass(item);
    setFormData({
      name: item.class_name,
      journalId: item.class_journal_id,
      mainTeacherId: item.class_mainteacher
    });
    setIsModalOpen(true);
  };

  const handleDelete = async (item) => {
    if (window.confirm(`Delete class ${item.class_name}?`)) {
      try {
        await deleteMutation.mutateAsync(item.class_name);
      } catch (error) {
        alert('Error deleting class: ' + error.message);
      }
    }
  };

  const handleCreate = () => {
    setEditingClass(null);
    setFormData({ name: '', journalId: '', mainTeacherId: '' });
    setIsModalOpen(true);
  };

  const handleSubmit = async (e) => {
    e.preventDefault();
    try {
      if (editingClass) {
        await updateMutation.mutateAsync({
          name: editingClass.class_name,
          newName: formData.name,
          journalId: formData.journalId,
          mainTeacherId: formData.mainTeacherId
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
    { header: 'Name', accessor: 'class_name' },
    { header: 'Journal', accessor: 'class_journal_id' },
    { header: 'Main Teacher', accessor: 'class_mainteacher' },
  ];

  return (
    <>
      <DataTable
        title="Classes"
        data={classes}
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
        title={editingClass ? 'Edit Class' : 'Create Class'}
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
            <label className="block text-sm font-medium text-gray-700">Journal</label>
            <select
              value={formData.journalId}
              onChange={(e) => setFormData({ ...formData, journalId: e.target.value })}
              className="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-indigo-500 focus:ring-indigo-500 sm:text-sm text-gray-900"
            >
              <option value="">Select Journal</option>
              {journals?.map((j) => (
                <option key={j.journal_id} value={j.journal_id}>
                  {j.journal_name}
                </option>
              ))}
            </select>
          </div>
          <div>
            <label className="block text-sm font-medium text-gray-700">Main Teacher</label>
            <select
              value={formData.mainTeacherId}
              onChange={(e) => setFormData({ ...formData, mainTeacherId: e.target.value })}
              className="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-indigo-500 focus:ring-indigo-500 sm:text-sm text-gray-900"
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
              {editingClass ? 'Update' : 'Create'}
            </button>
          </div>
        </form>
      </Modal>
    </>
  );
}
