import React, { useState, useMemo } from 'react';
import DataTable from '../../../common/DataTable';
import { useUsers } from '../../../../hooks/users/queries/useUsers';
import { useCreateUser } from '../../../../hooks/users/mutations/useCreateUser';
import { useUpdateUser } from '../../../../hooks/users/mutations/useUpdateUser';
import { useDeleteUser } from '../../../../hooks/users/mutations/useDeleteUser';
import { useAdminPermissions } from '../../../../hooks/useAdminPermissions';
import { useUserRoles } from '../../../../hooks/userroles/queries/useUserRoles';
import Modal from '../../../common/Modal';
import { useAssignRole } from '../../../../hooks/userroles/mutations/useAssignRole';
import { useRemoveRoleFromUser } from '../../../../hooks/userroles/mutations/useRemoveRoleFromUser';
import { useResetPassword } from '../../../../hooks/users/mutations/useResetPassword';

const ROLE_MAP = {
  1: 'SAdmin',
  2: 'Admin',
  4: 'Student',
  6: 'Parent',
  7: 'Teacher',
  8: 'Guest'
};

export default function UsersTable() {
  const { data: usersData, isLoading: usersLoading } = useUsers();
  const { data: userRolesData, isLoading: rolesLoading } = useUserRoles();
  const { permissions } = useAdminPermissions();
  
  const createMutation = useCreateUser();
  const updateMutation = useUpdateUser();
  const deleteMutation = useDeleteUser();
  const assignRoleMutation = useAssignRole();
  const removeRoleMutation = useRemoveRoleFromUser();
  const resetPasswordMutation = useResetPassword();

  const [isModalOpen, setIsModalOpen] = useState(false);
  const [isRoleModalOpen, setIsRoleModalOpen] = useState(false);
  const [isPasswordModalOpen, setIsPasswordModalOpen] = useState(false);
  const [editingUser, setEditingUser] = useState(null);
  const [formData, setFormData] = useState({
    username: '',
    email: '',
    password: ''
  });
  const [roleFormData, setRoleFormData] = useState({
    roleId: ''
  });
  const [passwordFormData, setPasswordFormData] = useState({
    newPassword: ''
  });

  const userRoles = userRolesData?.roles || [];

  // Map user roles to their names
  const userRolesMap = userRoles.reduce((acc, role) => {
    const roleName = ROLE_MAP[role.role_id] || `Role ${role.role_id}`;
    if (acc[role.user_id]) {
      acc[role.user_id] += `, ${roleName}`;
    } else {
      acc[role.user_id] = roleName;
    }
    return acc;
  }, {});

  // Enrich users with role names
  const users = useMemo(() => 
    usersData?.map(user => ({
      ...user,
      role_name: userRolesMap[user.user_id] || 'Unknown'
    })).sort((a, b) => a.user_id - b.user_id) || [], [usersData, userRolesMap]);

  const handleEdit = (item) => {
    setEditingUser(item);
    setFormData({
      username: item.username,
      email: item.email,
      password: '' // Don't show existing password
    });
    setIsModalOpen(true);
  };

  const handleDelete = async (item) => {
    if (window.confirm(`Delete user ${item.username}?`)) {
      try {
        await deleteMutation.mutateAsync(item.user_id);
      } catch (error) {
        console.error('Failed to delete user:', error);
        alert('Failed to delete user');
      }
    }
  };

  const handleCreate = () => {
    setEditingUser(null);
    setFormData({
      username: '',
      email: '',
      password: ''
    });
    setIsModalOpen(true);
  };

  const handleSubmit = async (e) => {
    e.preventDefault();
    try {
      const dataToSubmit = {
        username: formData.username,
        email: formData.email,
        password: formData.password
      };

      if (editingUser) {
        // If password is empty during update, we might need to handle it.
        // But based on backend, it seems to require password.
        // I'll warn if password is empty for update.
        if (!formData.password) {
            alert("Password is required for update (backend limitation).");
            return;
        }
        await updateMutation.mutateAsync({
          id: editingUser.user_id,
          ...dataToSubmit
        });
      } else {
        await createMutation.mutateAsync(dataToSubmit);
      }
      setIsModalOpen(false);
    } catch (error) {
      console.error('Failed to save user:', error);
      alert('Failed to save user');
    }
  };

  const handleManageRoles = (item) => {
    setEditingUser(item);
    setRoleFormData({ roleId: '' });
    setIsRoleModalOpen(true);
  };

  const handleResetPassword = (item) => {
    setEditingUser(item);
    setPasswordFormData({ newPassword: '' });
    setIsPasswordModalOpen(true);
  };

  const handleRoleSubmit = async (e) => {
    e.preventDefault();
    try {
      await assignRoleMutation.mutateAsync({
        userId: editingUser.user_id,
        roleId: parseInt(roleFormData.roleId)
      });
      setIsRoleModalOpen(false);
    } catch (error) {
      alert('Error assigning role: ' + error.message);
    }
  };

  const handleRemoveRole = async (roleId) => {
    if (window.confirm('Are you sure you want to remove this role?')) {
      try {
        await removeRoleMutation.mutateAsync({
          userId: parseInt(editingUser.user_id),
          roleId: parseInt(roleId)
        });
      } catch (error) {
        alert('Error removing role: ' + error.message);
      }
    }
  };

  const handlePasswordSubmit = async (e) => {
    e.preventDefault();
    try {
      await resetPasswordMutation.mutateAsync({
        userId: editingUser.user_id,
        newPassword: passwordFormData.newPassword
      });
      setIsPasswordModalOpen(false);
      alert('Password reset successfully');
    } catch (error) {
      alert('Error resetting password: ' + error.message);
    }
  };

  const columns = [
    { header: 'ID', accessor: 'user_id' },
    { header: 'Username', accessor: 'username' },
    { header: 'Email', accessor: 'email' },
    { header: 'Roles', accessor: 'role_name' },
    {
      header: 'Actions',
      render: (item) => (
        <div className="flex space-x-2">
          {(permissions.users.edit) && (
          <button
            onClick={() => handleEdit(item)}
            className="text-indigo-600 hover:text-indigo-900"
          >
            Edit
          </button>
          )}
          {(permissions.users.managingRoles) && (
          <button
            onClick={() => handleManageRoles(item)}
            className="text-green-600 hover:text-green-900"
          >
            Roles
          </button>
          )}
          {(permissions.users.resetPassword) && (
            <button
              onClick={() => handleResetPassword(item)}
              className="text-yellow-600 hover:text-yellow-900"
            >
              Reset Pwd
            </button>
          )}
          {(permissions.users.delete) && (
          <button
            onClick={() => handleDelete(item)}
            className="text-red-600 hover:text-red-900"
          >
            Delete
          </button>
          )}
        </div>
      )
    }
  ];

  return (
    <>
      <DataTable
        title="Users"
        data={users}
        columns={columns}
        isLoading={usersLoading || rolesLoading}
        onEdit={handleEdit}
        onDelete={handleDelete}
        onCreate={handleCreate}
        canEdit={false} // Custom actions column handles this
        canDelete={false} // Custom actions column handles this
        canCreate={permissions.users.create}
      />

      <Modal
        isOpen={isModalOpen}
        onClose={() => setIsModalOpen(false)}
        title={editingUser ? 'Edit User' : 'Create User'}
      >
        <form onSubmit={handleSubmit} className="space-y-4">
          <div>
            <label className="block text-sm font-medium text-gray-700">Username</label>
            <input
              type="text"
              value={formData.username}
              onChange={(e) => setFormData({ ...formData, username: e.target.value })}
              className="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-indigo-500 focus:ring-indigo-500 sm:text-sm"
              required
            />
          </div>
          <div>
            <label className="block text-sm font-medium text-gray-700">Email</label>
            <input
              type="email"
              value={formData.email}
              onChange={(e) => setFormData({ ...formData, email: e.target.value })}
              className="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-indigo-500 focus:ring-indigo-500 sm:text-sm"
              required
            />
          </div>
          <div>
            <label className="block text-sm font-medium text-gray-700">
              Password {editingUser && '(Required for update)'}
            </label>
            <input
              type="password"
              value={formData.password}
              onChange={(e) => setFormData({ ...formData, password: e.target.value })}
              className="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-indigo-500 focus:ring-indigo-500 sm:text-sm"
              required={!editingUser} // Required for create, and effectively for update too
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
              {editingUser ? 'Update' : 'Create'}
            </button>
          </div>
        </form>
      </Modal>

      <Modal
        isOpen={isRoleModalOpen}
        onClose={() => setIsRoleModalOpen(false)}
        title={`Manage Roles for ${editingUser?.username}`}
      >
        <div className="space-y-4">
          <div className="border-b pb-4">
            <h4 className="text-sm font-medium text-gray-700 mb-2">Current Roles</h4>
            <div className="flex flex-wrap gap-2">
              {userRoles
                .filter(r => r.user_id === editingUser?.user_id)
                .map(r => (
                  <span key={r.role_id} className="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium bg-blue-100 text-blue-800">
                    {ROLE_MAP[r.role_id]}
                    <button
                      onClick={() => handleRemoveRole(r.role_id)}
                      className="ml-1.5 text-blue-600 hover:text-blue-800"
                    >
                      ×
                    </button>
                  </span>
                ))}
            </div>
          </div>

          <form onSubmit={handleRoleSubmit} className="space-y-4">
            <div>
              <label className="block text-sm font-medium text-gray-700">Add Role</label>
              <select
                value={roleFormData.roleId}
                onChange={(e) => setRoleFormData({ roleId: e.target.value })}
                className="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-indigo-500 focus:ring-indigo-500 sm:text-sm"
                required
              >
                <option value="">Select Role</option>
                {Object.entries(ROLE_MAP).map(([id, name]) => (
                  <option key={id} value={id}>{name}</option>
                ))}
              </select>
            </div>
            <div className="flex justify-end space-x-3">
              <button
                type="button"
                onClick={() => setIsRoleModalOpen(false)}
                className="rounded-md border border-gray-300 bg-white px-4 py-2 text-sm font-medium text-gray-700 shadow-sm hover:bg-gray-50"
              >
                Close
              </button>
              <button
                type="submit"
                className="rounded-md border border-transparent bg-indigo-600 px-4 py-2 text-sm font-medium text-white shadow-sm hover:bg-indigo-700"
              >
                Add Role
              </button>
            </div>
          </form>
        </div>
      </Modal>

      <Modal
        isOpen={isPasswordModalOpen}
        onClose={() => setIsPasswordModalOpen(false)}
        title={`Reset Password for ${editingUser?.username}`}
      >
        <form onSubmit={handlePasswordSubmit} className="space-y-4">
          <div>
            <label className="block text-sm font-medium text-gray-700">New Password</label>
            <input
              type="password"
              value={passwordFormData.newPassword}
              onChange={(e) => setPasswordFormData({ newPassword: e.target.value })}
              className="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-indigo-500 focus:ring-indigo-500 sm:text-sm"
              required
            />
          </div>
          <div className="flex justify-end space-x-3 pt-4">
            <button
              type="button"
              onClick={() => setIsPasswordModalOpen(false)}
              className="rounded-md border border-gray-300 bg-white px-4 py-2 text-sm font-medium text-gray-700 shadow-sm hover:bg-gray-50"
            >
              Cancel
            </button>
            <button
              type="submit"
              className="rounded-md border border-transparent bg-yellow-600 px-4 py-2 text-sm font-medium text-white shadow-sm hover:bg-yellow-700"
            >
              Reset Password
            </button>
          </div>
        </form>
      </Modal>
    </>
  );
}
