import React, { useState } from 'react';
import DataTable from '../../../common/DataTable';
import { useTeachers } from '../../../../hooks/teachers/queries/useTeachers';
import { useCreateTeacher } from '../../../../hooks/teachers/mutations/useCreateTeacher';
import { useUpdateTeacher } from '../../../../hooks/teachers/mutations/useUpdateTeacher';
import { useDeleteTeacher } from '../../../../hooks/teachers/mutations/useDeleteTeacher';
import { useUsers } from '../../../../hooks/users/queries/useUsers';
import { useAdminPermissions } from '../../../../hooks/useAdminPermissions';
import Modal from '../../../common/Modal';

export default function TeachersTable() {
  const { data: teachers, isLoading } = useTeachers();
  const { data: users } = useUsers();
  const { permissions } = useAdminPermissions();
  
  const createMutation = useCreateTeacher();
  const updateMutation = useUpdateTeacher();
  const deleteMutation = useDeleteTeacher();

  const [isModalOpen, setIsModalOpen] = useState(false);
  const [editingTeacher, setEditingTeacher] = useState(null);
  const [formData, setFormData] = useState({
    name: '',
    surname: '',
    patronym: '',
    phone: '',
  });

  const handleEdit = (item) => {
    setEditingTeacher(item);
    setFormData({
      name: item.teacher_name,
      surname: item.teacher_surname,
      patronym: item.teacher_patronym,
      phone: item.teacher_phone,
    });
    setIsModalOpen(true);
  };

  const handleDelete = async (item) => {
    if (window.confirm(`Delete teacher ${item.teacher_name} ${item.teacher_surname}?`)) {
      try {
        await deleteMutation.mutateAsync(item.teacher_id);
      } catch (error) {
        console.error('Failed to delete teacher:', error);
        alert('Failed to delete teacher');
      }
    }
  };

  const handleCreate = () => {
    setEditingTeacher(null);
    setFormData({
      name: '',
      surname: '',
      patronym: '',
      phone: '',
    });
    setIsModalOpen(true);
  };

  const handleSubmit = async (e) => {
    e.preventDefault();
    const dataToSubmit = {
      name: formData.name,
      surname: formData.surname,
      patronym: formData.patronym || null,
      phone: formData.phone || null,
    };

    try {
      if (editingTeacher) {
        await updateMutation.mutateAsync({
          id: editingTeacher.teacher_id,
          ...dataToSubmit,
        });
      } else {
        await createMutation.mutateAsync(dataToSubmit);
      }
      setIsModalOpen(false);
    } catch (error) {
      console.error('Failed to save teacher:', error);
      alert('Failed to save teacher');
    }
  };

  const columns = [
    { header: 'ID', accessor: 'teacher_id' },
    { header: 'User', accessor: 'teacher_user_id' },
    { header: 'Name', accessor: 'teacher_name' },
    { header: 'Surname', accessor: 'teacher_surname' },
    { header: 'Patronym', accessor: 'teacher_patronym' },
    { header: 'Phone', accessor: 'teacher_phone' },
  ];

  return (
    <>
      <DataTable
        title="Teachers"
        data={teachers?.slice().sort((a, b) => a.teacher_id - b.teacher_id)}
        columns={columns}
        isLoading={isLoading}
        onEdit={handleEdit}
        onDelete={handleDelete}
        onCreate={handleCreate}
        canEdit={permissions.teachers.edit}
        canDelete={permissions.teachers.delete}
        canCreate={permissions.teachers.create}
      />

      <Modal
        isOpen={isModalOpen}
        onClose={() => setIsModalOpen(false)}
        title={editingTeacher ? 'Edit Teacher' : 'Create Teacher'}
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
            <label className="block text-sm font-medium text-gray-700">Surname</label>
            <input
              type="text"
              value={formData.surname}
              onChange={(e) => setFormData({ ...formData, surname: e.target.value })}
              className="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-indigo-500 focus:ring-indigo-500 sm:text-sm text-gray-900"
              required
            />
          </div>
          <div>
            <label className="block text-sm font-medium text-gray-700">Patronym</label>
            <input
              type="text"
              value={formData.patronym}
              onChange={(e) => setFormData({ ...formData, patronym: e.target.value })}
              className="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-indigo-500 focus:ring-indigo-500 sm:text-sm text-gray-900"
            />
          </div>
          <div>
            <label className="block text-sm font-medium text-gray-700">Phone</label>
            <input
              type="text"
              value={formData.phone}
              onChange={(e) => setFormData({ ...formData, phone: e.target.value })}
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
              {editingTeacher ? 'Update' : 'Create'}
            </button>
          </div>
        </form>
      </Modal>
    </>
  );
}
