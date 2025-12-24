import React, { useState } from 'react';
import DataTable from '../../../common/DataTable';
import { useDays } from '../../../../hooks/days/queries/useDays';
import { useCreateDay } from '../../../../hooks/days/mutations/useCreateDay';
import { useUpdateDay } from '../../../../hooks/days/mutations/useUpdateDay';
import { useDeleteDay } from '../../../../hooks/days/mutations/useDeleteDay';
import { useAdminPermissions } from '../../../../hooks/useAdminPermissions';
import { useSubjects } from '../../../../hooks/subjects/queries/useSubjects';
import { useTimetables } from '../../../../hooks/timetables/queries/useTimetables';
import Modal from '../../../common/Modal';

export default function DaysTable() {
  const { data: days, isLoading } = useDays();
  const { permissions } = useAdminPermissions();
  const { data: subjects } = useSubjects();
  const { data: timetables } = useTimetables();

  const createMutation = useCreateDay();
  const updateMutation = useUpdateDay();
  const deleteMutation = useDeleteDay();

  const [isModalOpen, setIsModalOpen] = useState(false);
  const [editingDay, setEditingDay] = useState(null);
  const [formData, setFormData] = useState({  
    dayTime: '', 
    dayWeekday: '',
    subjectId: '',
    timetableId: ''
  });

  const handleEdit = (item) => {
    setEditingDay(item);
    setFormData({
      dayTime: item.day_time || '',
      dayWeekday: item.day_weekday || '',
      subjectId: item.day_subject || '',
      timetableId: item.day_timetable || ''
    });
    setIsModalOpen(true);
  };

  const handleDelete = async (item) => {
    if (window.confirm(`Delete day ${item.day_id}?`)) {
      try {
        await deleteMutation.mutateAsync(item.day_id);
      } catch (error) {
        alert('Error deleting day: ' + error.message);
      }
    }
  };

  const handleCreate = () => {
    setEditingDay(null);
    setFormData({ 
      dayTime: '', 
      dayWeekday: '',
      subjectId: '',
      timetableId: ''
    });
    setIsModalOpen(true);
  };

  const handleSubmit = async (e) => {
    e.preventDefault();
    try {
      const dataToSubmit = {
        ...formData,
        subjectId: formData.subjectId ? parseInt(formData.subjectId) : null,
        timetableId: formData.timetableId ? parseInt(formData.timetableId) : null
      };

      if (editingDay) {
        await updateMutation.mutateAsync({
          id: editingDay.day_id,
          ...dataToSubmit
        });
      } else {
        await createMutation.mutateAsync(dataToSubmit);
      }
      setIsModalOpen(false);
    } catch (error) {
      console.error('Failed to save day:', error);
      alert('Failed to save day');
    }
  };

  const columns = [
    { header: 'ID', accessor: 'day_id' },
    { header: 'Subject', accessor: 'day_subject' },
    { header: 'Timetable', accessor: 'day_timetable' },
    { header: 'Weekday', accessor: 'day_weekday' },
    { header: 'Time', accessor: 'day_time' },
  ];

  return (
    <>
      <DataTable
        title="Days"
        data={days?.slice().sort((a, b) => a.day_id - b.day_id)}
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
        title={editingDay ? 'Edit Day' : 'Create Day'}
      >
        <form onSubmit={handleSubmit} className="space-y-4">
          <div>
            <label className="block text-sm font-medium text-gray-700">Subject</label>
            <select
              value={formData.subjectId}
              onChange={(e) => setFormData({ ...formData, subjectId: e.target.value })}
              className="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-indigo-500 focus:ring-indigo-500 sm:text-sm text-gray-900"
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
            <label className="block text-sm font-medium text-gray-700">Timetable</label>
            <select
              value={formData.timetableId}
              onChange={(e) => setFormData({ ...formData, timetableId: e.target.value })}
              className="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-indigo-500 focus:ring-indigo-500 sm:text-sm text-gray-900"
            >
              <option value="">Select Timetable</option>
              {timetables?.map((t) => (
                <option key={t.timetable_id} value={t.timetable_id}>
                  {t.timetable_name}
                </option>
              ))}
            </select>
          </div>
          <div>
            <label className="block text-sm font-medium text-gray-700">Weekday</label>
            <select
              value={formData.dayWeekday}
              onChange={(e) => setFormData({ ...formData, dayWeekday: e.target.value })}
              className="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-indigo-500 focus:ring-indigo-500 sm:text-sm text-gray-900"
              required
            >
              <option value="">Select Weekday</option>
              {['Понеділок', 'Вівторок', 'Середа', 'Четвер', 'Пʼятниця', 'Субота', 'Неділя'].map(d => (
                <option key={d} value={d}>{d}</option>
              ))}
            </select>
          </div>
          <div>
            <label className="block text-sm font-medium text-gray-700">Time</label>
            <input
              type="time"
              value={formData.dayTime}
              onChange={(e) => setFormData({ ...formData, dayTime: e.target.value })}
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
              {editingDay ? 'Update' : 'Create'}
            </button>
          </div>
        </form>
      </Modal>
    </>
  );
}
