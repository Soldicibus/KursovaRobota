import React, { useState } from 'react';
import DataTable from '../../../common/DataTable';
import { useParents } from '../../../../hooks/parents/queries/useParents';
import { useCreateParent } from '../../../../hooks/parents/mutations/useCreateParent';
import { useUpdateParent } from '../../../../hooks/parents/mutations/useUpdateParent';
import { useDeleteParent } from '../../../../hooks/parents/mutations/useDeleteParent';
import { useAdminPermissions } from '../../../../hooks/useAdminPermissions';
import Modal from '../../../common/Modal';
import { useStudents } from '../../../../hooks/students/queries/useStudents';
import { useAssignParentToStudent } from '../../../../hooks/studentparents/mutations/useAssignParentToStudent';

export default function ParentsTable() {
  const { data: parents, isLoading } = useParents();
  const { permissions } = useAdminPermissions();

  const createMutation = useCreateParent();
  const updateMutation = useUpdateParent();
  const deleteMutation = useDeleteParent();

  const [isModalOpen, setIsModalOpen] = useState(false);
  const [editingParent, setEditingParent] = useState(null);
  const [formData, setFormData] = useState({
    name: '', surname: '', patronym: '', phone: ''
  });
  const { data: students } = useStudents();
  const assignMutation = useAssignParentToStudent();
  const [isAssignModalOpen, setIsAssignModalOpen] = useState(false);
  const [assignData, setAssignData] = useState({ studentId: '', parentId: '' });

  const handleEdit = (item) => {
    setEditingParent(item);
    setFormData({
      name: item.parent_name || '',
      surname: item.parent_surname || '',
      patronym: item.parent_patronym || '',
      phone: item.parent_phone || ''
    });
    setIsModalOpen(true);
  };

  const handleDelete = async (item) => {
    if (window.confirm(`Delete parent ${item.parent_name} ${item.parent_surname}?`)) {
      try {
        await deleteMutation.mutateAsync(item.parent_id);
      } catch (error) {
        alert('Error deleting parent: ' + error.message);
      }
    }
  };

  const handleCreate = () => {
    setEditingParent(null);
    setFormData({ name: '', surname: '', patronym: '', phone: '' });
    setIsModalOpen(true);
  };

  const handleSubmit = async (e) => {
    e.preventDefault();
    try {
      if (editingParent) {
        await updateMutation.mutateAsync({
          id: editingParent.parent_id,
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
    { header: 'ID', accessor: 'parent_id' },
    { header: 'User', accessor: 'parent_user_id' },
    { header: 'Name', accessor: 'parent_name' },
    { header: 'Surname', accessor: 'parent_surname' },
    { header: 'Patronym', accessor: 'parent_patronym' },
    { header: 'Phone', accessor: 'parent_phone' },
  ];

  return (
    <>
      <DataTable
        title="Parents"
        data={parents?.slice().sort((a, b) => a.parent_id - b.parent_id)}
        columns={columns}
        isLoading={isLoading}
        onEdit={handleEdit}
        onDelete={handleDelete}
        onCreate={handleCreate}
        extraAction={
          <button
            type="button"
            onClick={() => { setAssignData({ studentId: '', parentId: '' }); setIsAssignModalOpen(true); }}
            className="ml-3 inline-flex items-center rounded-md border border-transparent bg-green-600 px-3 py-2 text-sm font-medium text-white shadow-sm hover:bg-green-700 focus:outline-none"
          >
            Assign Student
          </button>
        }
        canEdit={permissions.parents.edit}
        canDelete={permissions.parents.delete}
        canCreate={permissions.parents.create}
      />

      <Modal
        isOpen={isModalOpen}
        onClose={() => setIsModalOpen(false)}
        title={editingParent ? 'Edit Parent' : 'Create Parent'}
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
              {editingParent ? 'Update' : 'Create'}
            </button>
          </div>
        </form>
      </Modal>

      <Modal
        isOpen={isAssignModalOpen}
        onClose={() => setIsAssignModalOpen(false)}
        title={'Assign Student to Parent'}
      >
        <form
          onSubmit={async (e) => {
            e.preventDefault();
            try {
              await assignMutation.mutateAsync({ studentId: assignData.studentId, parentId: assignData.parentId });
              setIsAssignModalOpen(false);
            } catch (err) {
              alert('Error assigning student: ' + (err.message || err));
            }
          }}
          className="space-y-4"
        >
          <div>
            <label className="block text-sm font-medium text-gray-700">Student</label>
            <select
              value={assignData.studentId}
              onChange={(e) => setAssignData({ ...assignData, studentId: e.target.value })}
              className="mt-1 block w-full rounded-md border-gray-300 bg-white shadow-sm sm:text-sm text-gray-900"
              required
            >
              <option value="">Select student</option>
              {students?.map((s) => (
                <option key={s.student_id} value={s.student_id}>{`${s.student_name} ${s.student_surname}`}</option>
              ))}
            </select>
          </div>
          <div>
            <label className="block text-sm font-medium text-gray-700">Parent</label>
            <select
              value={assignData.parentId}
              onChange={(e) => setAssignData({ ...assignData, parentId: e.target.value })}
              className="mt-1 block w-full rounded-md border-gray-300 bg-white shadow-sm sm:text-sm text-gray-900"
              required
            >
              <option value="">Select parent</option>
              {parents?.map((p) => (
                <option key={p.parent_id} value={p.parent_id}>{`${p.parent_name} ${p.parent_surname}`}</option>
              ))}
            </select>
          </div>
          <div className="flex justify-end space-x-3 pt-4">
            <button
              type="button"
              onClick={() => setIsAssignModalOpen(false)}
              className="rounded-md border border-gray-300 bg-white px-4 py-2 text-sm font-medium text-gray-700 shadow-sm hover:bg-gray-50"
            >
              Cancel
            </button>
            <button
              type="submit"
              className="rounded-md border border-transparent bg-green-600 px-4 py-2 text-sm font-medium text-white shadow-sm hover:bg-green-700"
            >
              Assign
            </button>
          </div>
        </form>
      </Modal>
    </>
  );
}
