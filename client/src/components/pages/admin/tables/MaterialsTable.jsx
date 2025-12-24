import React, { useState } from 'react';
import DataTable from '../../../common/DataTable';
import { useMaterials } from '../../../../hooks/materials/queries/useMaterials';
import { useCreateMaterial } from '../../../../hooks/materials/mutations/useCreateMaterial';
import { useUpdateMaterial } from '../../../../hooks/materials/mutations/useUpdateMaterial';
import { useDeleteMaterial } from '../../../../hooks/materials/mutations/useDeleteMaterial';
import { useAdminPermissions } from '../../../../hooks/useAdminPermissions';
import Modal from '../../../common/Modal';

export default function MaterialsTable() {
  const { data: materials, isLoading } = useMaterials();
  const { permissions } = useAdminPermissions();

  const createMutation = useCreateMaterial();
  const updateMutation = useUpdateMaterial();
  const deleteMutation = useDeleteMaterial();

  const [isModalOpen, setIsModalOpen] = useState(false);
  const [editingMaterial, setEditingMaterial] = useState(null);
  const [formData, setFormData] = useState({ name: '', description: '', link: '' });

  const handleEdit = (item) => {
    setEditingMaterial(item);
    setFormData({
      name: item.material_name || '',
      description: item.material_desc || '',
      link: item.material_link || '',
    });
    setIsModalOpen(true);
  };

  const handleDelete = async (item) => {
    if (window.confirm(`Delete material ${item.material_name || item.material_id}?`)) {
      try {
        await deleteMutation.mutateAsync(item.material_id);
      } catch (error) {
        console.error('Failed to delete material:', error);
        alert('Failed to delete material');
      }
    }
  };

  const handleCreate = () => {
    setEditingMaterial(null);
    setFormData({ name: '', description: '', link: '' });
    setIsModalOpen(true);
  };

  const handleSubmit = async (e) => {
    e.preventDefault();
    try {
      const payload = {
        name: formData.name,
        description: formData.description || null,
        link: formData.link || null,
      };

      if (editingMaterial) {
        await updateMutation.mutateAsync({ id: editingMaterial.material_id, ...payload });
      } else {
        await createMutation.mutateAsync(payload);
      }
      setIsModalOpen(false);
    } catch (error) {
      console.error('Failed to save material:', error);
      alert('Failed to save material');
    }
  };

  const columns = [
    { header: 'ID', accessor: 'material_id' },
    { header: 'Name', accessor: 'material_name' },
    { header: 'Description', accessor: 'material_desc' },
    { header: 'Link', accessor: 'material_link' },
  ];

  return (
    <>
      <DataTable
        title="Materials"
        data={materials?.slice().sort((a, b) => a.material_id - b.material_id)}
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
        title={editingMaterial ? 'Edit Material' : 'Create Material'}
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
            <label className="block text-sm font-medium text-gray-700">Description</label>
            <textarea
              value={formData.description}
              onChange={(e) => setFormData({ ...formData, description: e.target.value })}
              className="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-indigo-500 focus:ring-indigo-500 sm:text-sm text-gray-900"
              rows={3}
            />
          </div>

          <div>
            <label className="block text-sm font-medium text-gray-700">Link</label>
            <input
              type="text"
              value={formData.link}
              onChange={(e) => setFormData({ ...formData, link: e.target.value })}
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
              {editingMaterial ? 'Update' : 'Create'}
            </button>
          </div>
        </form>
      </Modal>
    </>
  );
}
