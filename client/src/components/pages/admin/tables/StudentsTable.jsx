import React, { useState } from 'react';
import DataTable from '../../../common/DataTable';
import { useStudents } from '../../../../hooks/students/queries/useStudents';
import { useCreateStudent } from '../../../../hooks/students/mutations/useCreateStudent';
import { useUpdateStudent } from '../../../../hooks/students/mutations/useUpdateStudent';
import { useDeleteStudent } from '../../../../hooks/students/mutations/useDeleteStudent';
import { useCreateUser } from '../../../../hooks/users/mutations/useCreateUser';
import { useClasses } from '../../../../hooks/classes/queries/useClasses';
import { useParents } from '../../../../hooks/parents/queries/useParents';
import { useAssignParentToStudent } from '../../../../hooks/studentparents/mutations/useAssignParentToStudent';
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

export default function StudentsTable() {
  const { data: students, isLoading } = useStudents();
  const { permissions, isSAdmin } = useAdminPermissions();

  const createMutation = useCreateStudent();
  const updateMutation = useUpdateStudent();
  const deleteMutation = useDeleteStudent();
  const createUserMutation = useCreateUser();

  const { data: classes } = useClasses();

  const [isModalOpen, setIsModalOpen] = useState(false);
  const [editingStudent, setEditingStudent] = useState(null);
  const [formData, setFormData] = useState({
    name: '', surname: '', patronym: '', phone: '', class_c: ''
  });

  // User creation state
  const [createUserEnabled, setCreateUserEnabled] = useState(false);
  const [userData, setUserData] = useState({ username: '', email: '', password: '' });

  // assign modal state
  const [isAssignModalOpen, setIsAssignModalOpen] = useState(false);
  const [assignData, setAssignData] = useState({ studentId: '', parentId: '' });
  const { data: parents } = useParents();
  const assignMutation = useAssignParentToStudent();

  const [errorMessage, setErrorMessage] = useState(null);

  const handleEdit = (item) => {
    setEditingStudent(item);
    setFormData({
      name: item.student_name || '',
      surname: item.student_surname || '',
      patronym: item.student_patronym || '',
      phone: formatPhoneInput(item.student_phone || ''),
      class_c: item.student_class || item.class || item.class_name || ''
    });
    setIsModalOpen(true);
  };

  const handleDelete = async (item) => {
    if (window.confirm(`Delete student ${item.student_name} ${item.student_surname}?`)) {
      try {
        await deleteMutation.mutateAsync(item.student_id);
      } catch (error) {
        setErrorMessage('Error deleting student: ' + error.message);
      }
    }
  };

  const handleCreate = () => {
    setEditingStudent(null);
    setFormData({ name: '', surname: '', patronym: '', phone: '', class_c: '' });
    setCreateUserEnabled(false);
    setUserData({ username: '', email: '', password: '' });
    setIsModalOpen(true);
  };

  const handleOpenAssign = () => {
    setAssignData({ studentId: '', parentId: '' });
    setIsAssignModalOpen(true);
  };

  const handleAssignSubmit = async (e) => {
    e.preventDefault();
    try {
      await assignMutation.mutateAsync({ studentId: assignData.studentId, parentId: assignData.parentId });
      setIsAssignModalOpen(false);
    } catch (error) {
      setErrorMessage('Error assigning parent: ' + error.message);
    }
  };

  const handleSubmit = async (e) => {
    e.preventDefault();
    try {
      let createdUserId = null;

      if (!editingStudent && createUserEnabled) {
        const userResponse = await createUserMutation.mutateAsync(userData);
        // Assuming response structure, adjust if API returns different structure
        createdUserId = userResponse?.user_id || userResponse?.id || userResponse?.user?.user_id;
        if (!createdUserId) throw new Error("Failed to retrieve new User ID");
      }

      const payload = {
        name: formData.name,
        surname: formData.surname,
        patronym: formData.patronym || null,
        phone: formData.phone,
        class_c: formData.class_c || null,
        user_id: createdUserId
      };

      if (editingStudent) {
        await updateMutation.mutateAsync({
          id: editingStudent.student_id,
          ...payload
        });
      } else {
        await createMutation.mutateAsync(payload);
      }
      setIsModalOpen(false);
    } catch (error) {
      setErrorMessage('Error: ' + error.message);
    }
  };

  const columns = [
    { header: 'ID', accessor: 'student_id' },
    { header: 'User', accessor: 'student_user_id' },
    { header: 'Name', accessor: 'student_name' },
    { header: 'Surname', accessor: 'student_surname' },
    { header: 'Patronym', accessor: 'student_patronym' },
    { header: 'Phone', accessor: 'student_phone' },
    { header: 'Class', accessor: 'student_class' },
  ];

  return (
    <>
      <DataTable
        title="Students"
        data={students?.slice().sort((a, b) => a.student_id - b.student_id)}
        columns={columns}
        isLoading={isLoading}
        onEdit={handleEdit}
        onDelete={handleDelete}
        onCreate={handleCreate}
        extraAction={
          <button className="btn btn-secondary" onClick={handleOpenAssign}>Assign to Parent</button>
        }
        canEdit={permissions.students.edit}
        canDelete={permissions.students.delete}
        canCreate={permissions.students.create}
      />
      
      <ErrorModal 
        error={errorMessage} 
        onClose={() => setErrorMessage(null)} 
      />

      <Modal
        isOpen={isModalOpen}
        onClose={() => setIsModalOpen(false)}
        title={editingStudent ? 'Edit Student' : 'Create Student'}
      >
        <form onSubmit={handleSubmit} className="space-y-4">
          {!editingStudent && isSAdmin && (
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
          <div>
            <label className="block text-sm font-medium text-gray-700">Class</label>
            <select
              value={formData.class_c}
              onChange={(e) => setFormData({ ...formData, class_c: e.target.value })}
              className="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-indigo-500 focus:ring-indigo-500 sm:text-sm text-gray-900"
            >
              <option value="">Select Class</option>
              {classes?.map((c) => (
                <option key={c.class_name} value={c.class_name}>
                  {c.class_name}
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
              {editingStudent ? 'Update' : 'Create'}
            </button>
          </div>
        </form>
      </Modal>

      <Modal
        isOpen={isAssignModalOpen}
        onClose={() => setIsAssignModalOpen(false)}
        title="Assign Student to Parent"
      >
        <form onSubmit={handleAssignSubmit} className="space-y-4">
          <div>
            <label className="block text-sm font-medium text-gray-700">Student</label>
            <select
              value={assignData.studentId}
              onChange={(e) => setAssignData({ ...assignData, studentId: e.target.value })}
              className="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-indigo-500 focus:ring-indigo-500 sm:text-sm text-gray-900"
              required
            >
              <option value="">Select Student</option>
              {students?.map((s) => (
                <option key={s.student_id} value={s.student_id}>{s.student_name} {s.student_surname}</option>
              ))}
            </select>
          </div>
          <div>
            <label className="block text-sm font-medium text-gray-700">Parent</label>
            <select
              value={assignData.parentId}
              onChange={(e) => setAssignData({ ...assignData, parentId: e.target.value })}
              className="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-indigo-500 focus:ring-indigo-500 sm:text-sm text-gray-900"
              required
            >
              <option value="">Select Parent</option>
              {parents?.map((p) => (
                <option key={p.parent_id} value={p.parent_id}>{p.parent_name} {p.parent_surname}</option>
              ))}
            </select>
          </div>
          <div className="flex justify-end space-x-3 pt-4">
            <button type="button" onClick={() => setIsAssignModalOpen(false)} className="rounded-md border border-gray-300 bg-white px-4 py-2 text-sm font-medium text-gray-700">Cancel</button>
            <button type="submit" className="rounded-md border border-transparent bg-indigo-600 px-4 py-2 text-sm font-medium text-white">Assign</button>
          </div>
        </form>
      </Modal>
    </>
  );
}
