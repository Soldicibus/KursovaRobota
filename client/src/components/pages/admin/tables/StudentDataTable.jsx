import React, { useState } from "react";
import DataTable from "../../../common/DataTable";
import { useStudentData } from "../../../../hooks/studentdata/queries/useStudentData";
import { useCreateStudentData } from "../../../../hooks/studentdata/mutations/useCreateStudentData";
import { useUpdateStudentData } from "../../../../hooks/studentdata/mutations/useUpdateStudentData";
import { useDeleteStudentData } from "../../../../hooks/studentdata/mutations/useDeleteStudentData";
import { useJournals } from "../../../../hooks/journals/queries/useJournals";
import { useStudents } from "../../../../hooks/students/queries/useStudents";
import { useLessons } from "../../../../hooks/lessons/queries/useLessons";
import { useAdminPermissions } from "../../../../hooks/useAdminPermissions";
import Modal from "../../../common/Modal";

export default function StudentDataTable() {
  const { data: studentData, isLoading } = useStudentData();
  const { permissions } = useAdminPermissions();

  const createMutation = useCreateStudentData();
  const updateMutation = useUpdateStudentData();
  const deleteMutation = useDeleteStudentData();

  const { data: journals } = useJournals();
  const { data: students } = useStudents();
  const { data: lessons } = useLessons();

  const [isModalOpen, setIsModalOpen] = useState(false);
  const [editingData, setEditingData] = useState(null);
  const [formData, setFormData] = useState({
    journalId: "",
    studentId: "",
    lesson: "",
    mark: "",
    status: "",
    note: "",
  });

  const handleEdit = (item) => {
    setEditingData(item);
    setFormData({
      journalId: item.data_journal || "",
      studentId: item.data_student || "",
      lesson: item.data_lesson || "",
      mark: item.data_mark || "",
      status: item.data_status || "",
      note: item.data_note || "",
    });
    setIsModalOpen(true);
  };

  const handleDelete = async (item) => {
    if (window.confirm(`Delete student data ${item.data_id}?`)) {
      try {
        await deleteMutation.mutateAsync(item.data_id);
      } catch (error) {
        alert("Error deleting student data: " + error.message);
      }
    }
  };

  const handleCreate = () => {
    setEditingData(null);
    setFormData({
      journalId: "",
      studentId: "",
      lesson: "",
      mark: "",
      status: "",
      note: "",
    });
    setIsModalOpen(true);
  };

  const handleSubmit = async (e) => {
    e.preventDefault();
    try {
      const payload = {
        journalId: formData.journalId,
        studentId: formData.studentId,
        lesson: formData.lesson,
        mark: formData.mark,
        status: formData.status,
        note: formData.note,
      };

      if (editingData) {
        await updateMutation.mutateAsync({
          id: editingData.data_id,
          ...payload,
        });
      } else {
        await createMutation.mutateAsync(payload);
      }
      setIsModalOpen(false);
    } catch (error) {
      alert("Error: " + error.message);
    }
  };

  const columns = [
    { header: "ID", accessor: "data_id" },
    { header: "Journal", accessor: "journal_id" },
    { header: "Student", accessor: "student_id" },
    { header: "Lesson", accessor: "lesson" },
    { header: "Mark", accessor: "mark" },
    { header: "Status", accessor: "status" },
    { header: "Note", accessor: "note" },
  ];

  return (
    <>
      <DataTable
        title="Student Data"
        data={studentData?.slice().sort((a, b) => a.data_id - b.data_id)}
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
        title={editingData ? "Edit Student Data" : "Create Student Data"}
      >
        <form onSubmit={handleSubmit} className="space-y-4">
          <div>
            <label className="block text-sm font-medium text-gray-700">
              Journal
            </label>
            <select
              value={formData.journalId}
              onChange={(e) =>
                setFormData({ ...formData, journalId: e.target.value })
              }
              className="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-indigo-500 focus:ring-indigo-500 sm:text-sm text-gray-900"
              required
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
            <label className="block text-sm font-medium text-gray-700">
              Student
            </label>
            <select
              value={formData.studentId}
              onChange={(e) =>
                setFormData({ ...formData, studentId: e.target.value })
              }
              className="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-indigo-500 focus:ring-indigo-500 sm:text-sm text-gray-900"
              required
            >
              <option value="">Select Student</option>
              {students?.map((s) => (
                <option key={s.student_id} value={s.student_id}>
                  {s.student_name} {s.student_surname}
                </option>
              ))}
            </select>
          </div>
          <div>
            <label className="block text-sm font-medium text-gray-700">
              Lesson
            </label>
            <select
              value={formData.lesson}
              onChange={(e) =>
                setFormData({ ...formData, lesson: e.target.value })
              }
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
            <label className="block text-sm font-medium text-gray-700">
              Mark
            </label>
            <input
              type="number"
              value={formData.mark}
              onChange={(e) =>
                setFormData({ ...formData, mark: e.target.value })
              }
              className="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-indigo-500 focus:ring-indigo-500 sm:text-sm text-gray-900"
            />
          </div>
          <div>
            <label className="block text-sm font-medium text-gray-700">
              Status
            </label>
            <select
              value={formData.status}
              onChange={(e) =>
                setFormData({ ...formData, status: e.target.value })
              }
              className="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-indigo-500 focus:ring-indigo-500 sm:text-sm text-gray-900"
            >
              <option value="">-- Оберіть статус --</option>
              <option value="Н">Н</option>
              <option value="П">П</option>
              <option value="Не присутній">Не присутній</option>
              <option value="Присутній">Присутній</option>
            </select>
          </div>
          <div>
            <label className="block text-sm font-medium text-gray-700">
              Note
            </label>
            <textarea
              value={formData.note}
              onChange={(e) =>
                setFormData({ ...formData, note: e.target.value })
              }
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
              {editingData ? "Update" : "Create"}
            </button>
          </div>
        </form>
      </Modal>
    </>
  );
}
