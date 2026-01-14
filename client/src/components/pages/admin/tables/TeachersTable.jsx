import React, { useState } from 'react';
import DataTable from '../../../common/DataTable';
import { useTeachers } from '../../../../hooks/teachers/queries/useTeachers';
import { useCreateTeacher } from '../../../../hooks/teachers/mutations/useCreateTeacher';
import { useUpdateTeacher } from '../../../../hooks/teachers/mutations/useUpdateTeacher';
import { useDeleteTeacher } from '../../../../hooks/teachers/mutations/useDeleteTeacher';
import { useCreateUser } from '../../../../hooks/users/mutations/useCreateUser';
import { useUsers } from '../../../../hooks/users/queries/useUsers';
import { useAdminPermissions } from '../../../../hooks/useAdminPermissions';
import Modal from '../../../common/Modal';
import ErrorModal from '../../../common/ErrorModal';

const formatPhoneInput = (val) => {
  if (!val) return '';
  const digits = val.replace(/\D/g, '').slice(0, 10);
  if (digits.length < 4) return digits;
  if (digits.length < 7) return `${digits.slice(0, 3)}-${digits.slice(3)}`;
  return `${digits.slice(0, 3)}-${digits.slice(3, 6)}-${digits.slice(6)}`;
};

export default function TeachersTable() {
  const { data: teachers, isLoading } = useTeachers();
  const { data: users } = useUsers();
  const { permissions, isSAdmin } = useAdminPermissions();
  
  const [errorMessage, setErrorMessage] = useState(null);

  const createMutation = useCreateTeacher();
  const updateMutation = useUpdateTeacher();
  const deleteMutation = useDeleteTeacher();
  const createUserMutation = useCreateUser();

  const [isModalOpen, setIsModalOpen] = useState(false);
  const [editingTeacher, setEditingTeacher] = useState(null);
  const [formData, setFormData] = useState({
    name: '',
    surname: '',
    patronym: '',
    phone: '',
  });

  // User creation state
  const [createUserEnabled, setCreateUserEnabled] = useState(false);
  const [userData, setUserData] = useState({ username: '', email: '', password: '' });

  const handleEdit = (item) => {
    setEditingTeacher(item);
    setFormData({
      name: item.teacher_name,
      surname: item.teacher_surname,
      patronym: item.teacher_patronym,
      phone: formatPhoneInput(item.teacher_phone || ''),
    });
    setIsModalOpen(true);
  };

  const handleDelete = async (item) => {
    if (window.confirm(`Delete teacher ${item.teacher_name} ${item.teacher_surname}?`)) {
      try {
        await deleteMutation.mutateAsync(item.teacher_id);
      } catch (error) {
        console.error('Failed to delete teacher:', error);
        setErrorMessage('Failed to delete teacher: ' + (error.message || error));
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
    setCreateUserEnabled(false);
    setUserData({ username: '', email: '', password: '' });
    setIsModalOpen(true);
  };

  const handleSubmit = async (e) => {
    e.preventDefault();
    try {
      let createdUserId = null;

      if (!editingTeacher && createUserEnabled) {
        const userResponse = await createUserMutation.mutateAsync(userData);
        createdUserId = userResponse?.user_id || userResponse?.id || userResponse?.user?.user_id;
        if (!createdUserId) throw new Error("Failed to retrieve new User ID");
      }

      const dataToSubmit = {
        name: formData.name,
        surname: formData.surname,
        patronym: formData.patronym || null,
        phone: formData.phone, // Phone is NOT NULL
        user_id: createdUserId
      };

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
      setErrorMessage('Failed to save teacher: ' + (error.message || error));
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
      
      <ErrorModal error={errorMessage} onClose={() => setErrorMessage(null)} />

      <Modal
        isOpen={isModalOpen}
        onClose={() => setIsModalOpen(false)}
        title={editingTeacher ? 'Edit Teacher' : 'Create Teacher'}
      >
        <form onSubmit={handleSubmit} className="space-y-4">
          {!editingTeacher && isSAdmin && (
            <div className="bg-gray-50 p-3 rounded-md border border-gray-200">
              <div className="flex items-center mb-2">
                <input
                  id="createUser"
                  type="checkbox"
                  checked={createUserEnabled}
                  onChange={(e) => setCreateUserEnabled(e.target.checked)}
                  className="h-4 w-4 rounded border-gray-300 text-indigo-600 focus:ring-indigo-500"
                />
                <label htmlFor="createUser" className="ml-2 block text-sm text-gray-900 font-medium">
                  Create User Account
                </label>
              </div>
              
              {createUserEnabled && (
                <div className="space-y-3 pl-6 border-l-2 border-indigo-200 ml-1">
                  <div>
                    <label className="block text-xs font-medium text-gray-700">Username</label>
                    <input
                      type="text"
                      value={userData.username}
                      onChange={(e) => setUserData({ ...userData, username: e.target.value })}
                      className="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-indigo-500 focus:ring-indigo-500 sm:text-xs"
                      required={createUserEnabled}
                    />
                  </div>
                  <div>
                    <label className="block text-xs font-medium text-gray-700">Email</label>
                    <input
                      type="email"
                      value={userData.email}
                      onChange={(e) => setUserData({ ...userData, email: e.target.value })}
                      className="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-indigo-500 focus:ring-indigo-500 sm:text-xs"
                      required={createUserEnabled}
                    />
                  </div>
                  <div>
                    <label className="block text-xs font-medium text-gray-700">Password</label>
                    <input
                      type="password"
                      value={userData.password}
                      onChange={(e) => setUserData({ ...userData, password: e.target.value })}
                      className="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-indigo-500 focus:ring-indigo-500 sm:text-xs"
                      required={createUserEnabled}
                    />
                  </div>
                </div>
              )}
            </div>
          )}
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
              onChange={(e) => setFormData({ ...formData, phone: formatPhoneInput(e.target.value) })}
              placeholder="0xx-xxx-xxxx"
              pattern="[0-9]{3}-[0-9]{3}-[0-9]{4}"
              maxLength="12"
              className="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-indigo-500 focus:ring-indigo-500 sm:text-sm text-gray-900"
              required
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
