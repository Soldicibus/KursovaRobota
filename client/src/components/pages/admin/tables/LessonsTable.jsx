import React, { useState } from 'react';
import DataTable from '../../../common/DataTable';
import { useLessons } from '../../../../hooks/lessons/queries/useLessons';
import { useCreateLesson } from '../../../../hooks/lessons/mutations/useCreateLesson';
import { useUpdateLesson } from '../../../../hooks/lessons/mutations/useUpdateLesson';
import { useDeleteLesson } from '../../../../hooks/lessons/mutations/useDeleteLesson';
import { useClasses } from '../../../../hooks/classes/queries/useClasses';
import { useSubjects } from '../../../../hooks/subjects/queries/useSubjects';
import { useMaterials } from '../../../../hooks/materials/queries/useMaterials';
import { useTeachers } from '../../../../hooks/teachers/queries/useTeachers';
import { useAdminPermissions } from '../../../../hooks/useAdminPermissions';
import Modal from '../../../common/Modal';

export default function LessonsTable() {
  const { data: lessons, isLoading } = useLessons();
  const { permissions } = useAdminPermissions();

  const createMutation = useCreateLesson();
  const updateMutation = useUpdateLesson();
  const deleteMutation = useDeleteLesson();

  const { data: classes } = useClasses();
  const { data: subjects } = useSubjects();
  const { data: materials } = useMaterials();
  const { data: teachers } = useTeachers();

  const [isModalOpen, setIsModalOpen] = useState(false);
  const [editingLesson, setEditingLesson] = useState(null);
  const [formData, setFormData] = useState({
    name: '', className: '', subjectId: '', materialId: '', teacherId: '', date: ''
  });

  const handleEdit = (item) => {
    setEditingLesson(item);
    setFormData({
      name: item.lesson_name || '',
      className: item.class_name || '', 
      subjectId: item.lesson_subject || '',
      materialId: item.lesson_material || '',
      teacherId: item.lesson_teacher || '',
      date: item.lesson_date ? new Date(item.lesson_date).toISOString().split('T')[0] : ''
    });
    setIsModalOpen(true);
  };

  const handleDelete = async (item) => {
    if (window.confirm(`Delete lesson ${item.lesson_name}?`)) {
      try {
        await deleteMutation.mutateAsync(item.lesson_id);
      } catch (error) {
        alert('Error deleting lesson: ' + error.message);
      }
    }
  };

  const handleCreate = () => {
    setEditingLesson(null);
    setFormData({ name: '', className: '', subjectId: '', materialId: '', teacherId: '', date: '' });
    setIsModalOpen(true);
  };

  const handleSubmit = async (e) => {
    e.preventDefault();
    try {
      const payload = {
        name: formData.name,
        className: formData.className,
        subjectId: formData.subjectId,
        materialId: formData.materialId,
        teacherId: formData.teacherId,
        date: formData.date
      };

      if (editingLesson) {
        await updateMutation.mutateAsync({
          id: editingLesson.lesson_id,
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
    { header: 'ID', accessor: 'lesson_id' },
    { header: 'Name', accessor: 'lesson_name' },
    { header: 'Class', accessor: 'lesson_class' },
    { header: 'Date', accessor: 'lesson_date' },
    { header: 'Teacher ID', accessor: 'lesson_teacher' },
    { header: 'Subject ID', accessor: 'lesson_subject' },
  ];

  return (
    <>
      <DataTable
        title="Lessons"
        data={lessons?.slice().sort((a, b) => a.lesson_id - b.lesson_id)}
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
        title={editingLesson ? 'Edit Lesson' : 'Create Lesson'}
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
            <label className="block text-sm font-medium text-gray-700">Date</label>
            <input
              type="date"
              value={formData.date}
              onChange={(e) => setFormData({ ...formData, date: e.target.value })}
              className="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-indigo-500 focus:ring-indigo-500 sm:text-sm text-gray-900"
              required
            />
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
            <label className="block text-sm font-medium text-gray-700">Subject</label>
            <select
              value={formData.subjectId}
              onChange={(e) => setFormData({ ...formData, subjectId: e.target.value })}
              className="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-indigo-500 focus:ring-indigo-500 sm:text-sm text-gray-900"
              required
            >
              <option value="">Select Subject</option>
              {subjects?.map((s) => (
                <option key={s.subject_id} value={s.subject_id}>
                  {s.subject_name}
                </option>
              ))}
            </select>
          </div>
          <div>
            <label className="block text-sm font-medium text-gray-700">Material</label>
            <select
              value={formData.materialId}
              onChange={(e) => setFormData({ ...formData, materialId: e.target.value })}
              className="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-indigo-500 focus:ring-indigo-500 sm:text-sm text-gray-900"
            >
              <option value="">Select Material</option>
              {materials?.map((m) => (
                <option key={m.material_id} value={m.material_id}>
                  {m.material_name}
                </option>
              ))}
            </select>
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
              {editingLesson ? 'Update' : 'Create'}
            </button>
          </div>
        </form>
      </Modal>
    </>
  );
}
