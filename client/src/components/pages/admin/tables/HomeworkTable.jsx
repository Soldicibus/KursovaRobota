import React, { useState } from 'react';
import DataTable from '../../../common/DataTable';
import { useHomework } from '../../../../hooks/homework/queries/useHomework';
import { useCreateHomework } from '../../../../hooks/homework/mutations/useCreateHomework';
import { useUpdateHomework } from '../../../../hooks/homework/mutations/useUpdateHomework';
import { useDeleteHomework } from '../../../../hooks/homework/mutations/useDeleteHomework';
import { useTeachers } from '../../../../hooks/teachers/queries/useTeachers';
import { useLessons } from '../../../../hooks/lessons/queries/useLessons';
import { useClasses } from '../../../../hooks/classes/queries/useClasses';
import { useAdminPermissions } from '../../../../hooks/useAdminPermissions';
import Modal from '../../../common/Modal';

export default function HomeworkTable() {
  const { data: homework, isLoading } = useHomework();
  const { permissions } = useAdminPermissions();

  const createMutation = useCreateHomework();
  const updateMutation = useUpdateHomework();
  const deleteMutation = useDeleteHomework();

  const { data: teachers } = useTeachers();
  const { data: lessons } = useLessons();
  const { data: classes } = useClasses();

  const [isModalOpen, setIsModalOpen] = useState(false);
  const [editingHomework, setEditingHomework] = useState(null);
  const [formData, setFormData] = useState({
    name: '', teacherId: '', lessonId: '', dueDate: '', description: '', className: ''
  });

  const handleEdit = (item) => {
    setEditingHomework(item);
    setFormData({
      name: item.homework_name || '',
      teacherId: item.homework_teacher || '',
      lessonId: item.homework_lesson || '',
      dueDate: item.homework_duedate ? new Date(item.homework_duedate).toISOString().split('T')[0] : '',
      description: item.homework_desc || '',
      className: item.class_name || '' 
    });
    setIsModalOpen(true);
  };

  const handleDelete = async (item) => {
    if (window.confirm(`Delete homework ${item.homework_name}?`)) {
      try {
        await deleteMutation.mutateAsync(item.homework_id);
      } catch (error) {
        alert('Error deleting homework: ' + error.message);
      }
    }
  };

  const handleCreate = () => {
    setEditingHomework(null);
    setFormData({ name: '', teacherId: '', lessonId: '', dueDate: '', description: '', className: '' });
    setIsModalOpen(true);
  };

  const handleSubmit = async (e) => {
    e.preventDefault();
    try {
      const payload = {
        name: formData.name,
        teacherId: formData.teacherId,
        lessonId: formData.lessonId,
        dueDate: formData.dueDate,
        description: formData.description,
        className: formData.className
      };

      if (editingHomework) {
        await updateMutation.mutateAsync({
          id: editingHomework.homework_id,
          ...payload
        });
      } else {
        await createMutation.mutateAsync(payload);
      }
      setIsModalOpen(false);
    } catch (error) {
      alert('Error: ' + error.message);
    }
  };

  const columns = [
    { header: 'ID', accessor: 'homework_id' },
    { header: 'Name', accessor: 'homework_name' },
    { header: 'Description', accessor: 'homework_desc' },
    { header: 'Class', accessor: 'homework_class' },
    { header: 'Due Date', accessor: 'homework_duedate' },
    { header: 'Teacher ID', accessor: 'homework_teacher' },
    { header: 'Lesson ID', accessor: 'homework_lesson' },
    { header: 'Created At', accessor: 'homework_created_at' },
  ];

  return (
    <>
      <DataTable
        title="Homework"
        data={homework?.slice().sort((a, b) => a.homework_id - b.homework_id)}
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
        title={editingHomework ? 'Edit Homework' : 'Create Homework'}
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
          <div>
            <label className="block text-sm font-medium text-gray-700">Lesson</label>
            <select
              value={formData.lessonId}
              onChange={(e) => setFormData({ ...formData, lessonId: e.target.value })}
              className="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-indigo-500 focus:ring-indigo-500 sm:text-sm text-gray-900"
              required
            >
              <option value="">Select Lesson</option>
              {lessons?.map((l) => (
                <option key={l.lesson_id} value={l.lesson_id}>
                  {l.lesson_name}
                </option>
              ))}
            </select>
          </div>
          <div>
            <label className="block text-sm font-medium text-gray-700">Class</label>
            <select
              value={formData.className}
              onChange={(e) => setFormData({ ...formData, className: e.target.value })}
              className="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-indigo-500 focus:ring-indigo-500 sm:text-sm text-gray-900"
              required
            >
              <option value="">Select Class</option>
              {classes?.map((c) => (
                <option key={c.class_name} value={c.class_name}>
                  {c.class_name}
                </option>
              ))}
            </select>
          </div>
          <div>
            <label className="block text-sm font-medium text-gray-700">Due Date</label>
            <input
              type="date"
              value={formData.dueDate}
              onChange={(e) => setFormData({ ...formData, dueDate: e.target.value })}
              className="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-indigo-500 focus:ring-indigo-500 sm:text-sm text-gray-900"
              required
            />
          </div>
          <div>
            <label className="block text-sm font-medium text-gray-700">Description</label>
            <textarea
              value={formData.description}
              onChange={(e) => setFormData({ ...formData, description: e.target.value })}
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
              {editingHomework ? 'Update' : 'Create'}
            </button>
          </div>
        </form>
      </Modal>
    </>
  );
}
