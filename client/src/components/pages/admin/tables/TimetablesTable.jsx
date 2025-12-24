import React, { useState } from 'react';
import DataTable from '../../../common/DataTable';
import { useTimetables } from '../../../../hooks/timetables/queries/useTimetables';
import { useCreateTimetable } from '../../../../hooks/timetables/mutations/useCreateTimetable';
import { useUpdateTimetable } from '../../../../hooks/timetables/mutations/useUpdateTimetable';
import { useDeleteTimetable } from '../../../../hooks/timetables/mutations/useDeleteTimetable';
import { useClasses } from '../../../../hooks/classes/queries/useClasses';
import { useAdminPermissions } from '../../../../hooks/useAdminPermissions';
import Modal from '../../../common/Modal';

export default function TimetablesTable() {
  const { data: timetables, isLoading } = useTimetables();
  const { data: classes } = useClasses();
  const { permissions } = useAdminPermissions();
  
  const createMutation = useCreateTimetable();
  const updateMutation = useUpdateTimetable();
  const deleteMutation = useDeleteTimetable();

  const [isModalOpen, setIsModalOpen] = useState(false);
  const [editingTimetable, setEditingTimetable] = useState(null);
  const [formData, setFormData] = useState({
    name: '',
    class_name: ''
  });

  const handleEdit = (item) => {
    setEditingTimetable(item);
    setFormData({
      name: item.timetable_name,
      class_name: item.timetable_class
    });
    setIsModalOpen(true);
  };

  const handleDelete = async (item) => {
    if (window.confirm(`Delete timetable ${item.timetable_name}?`)) {
      try {
        await deleteMutation.mutateAsync(item.timetable_id);
      } catch (error) {
        console.error('Failed to delete timetable:', error);
        alert('Failed to delete timetable');
      }
    }
  };

  const handleCreate = () => {
    setEditingTimetable(null);
    setFormData({
      name: '',
      class_name: ''
    });
    setIsModalOpen(true);
  };

  const handleSubmit = async (e) => {
    e.preventDefault();
    try {
      const dataToSubmit = {
        name: formData.name,
        class_name: formData.class_name
      };

      if (editingTimetable) {
        await updateMutation.mutateAsync({
          id: editingTimetable.timetable_id,
          ...dataToSubmit
        });
      } else {
        await createMutation.mutateAsync(dataToSubmit);
      }
      setIsModalOpen(false);
    } catch (error) {
      console.error('Failed to save timetable:', error);
      alert('Failed to save timetable');
    }
  };

  const columns = [
    { header: 'ID', accessor: 'timetable_id' },
    { header: 'Name', accessor: 'timetable_name' },
    { header: 'Class', accessor: 'timetable_class' },
  ];

  return (
    <>
      <DataTable
        title="Timetables"
        data={timetables?.slice().sort((a, b) => a.timetable_id - b.timetable_id)}
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
        title={editingTimetable ? 'Edit Timetable' : 'Create Timetable'}
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
            <label className="block text-sm font-medium text-gray-700">Class</label>
            <select
              value={formData.class_name}
              onChange={(e) => setFormData({ ...formData, class_name: e.target.value })}
              className="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-indigo-500 focus:ring-indigo-500 sm:text-sm text-gray-900"
              required
            >
              <option value="">Select Class</option>
              {classes?.map((cls) => (
                <option key={cls.class_name} value={cls.class_name}>
                  {cls.class_name}
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
              {editingTimetable ? 'Update' : 'Create'}
            </button>
          </div>
        </form>
      </Modal>
    </>
  );
}
