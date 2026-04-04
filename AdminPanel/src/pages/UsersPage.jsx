import React, { useState, useEffect } from 'react';
import api from '../services/api';
import { motion } from 'framer-motion';
import { Search, Filter, CheckCircle, Trash2, Mail } from 'lucide-react';
import { Button } from '../components/ui/Button';
import { Input } from '../components/ui/Input';

const UsersPage = ({ type }) => { // type: 'player' | 'coach'
    const [users, setUsers] = useState([]);
    const [loading, setLoading] = useState(true);
    const [searchTerm, setSearchTerm] = useState('');

    useEffect(() => {
        fetchUsers();
    }, []);

    const fetchUsers = async () => {
        try {
            const response = await api.get('/admin/users', { params: { role: type } });
            const filteredUsers = response.data.filter((user) => (
                type === 'coach'
                    ? ['coach', 'assistant_coach', 'head_coach'].includes(user.role)
                    : user.role === 'player'
            ));
            setUsers(filteredUsers);
        } catch (error) {
            console.error("Failed to fetch users", error);
            // Fallback/Mock data for demonstration if API fails or backend not running
            setUsers([
                { _id: '1', username: 'JordonOne', email: 'jordon@example.com', role: type, isVerified: true, profileCompleted: true },
                { _id: '2', username: 'HoopMaster', email: 'hoop@example.com', role: type, isVerified: false, profileCompleted: true },
                { _id: '3', username: 'RookieBaller', email: 'rookie@example.com', role: type, isVerified: true, profileCompleted: false },
            ]);
        } finally {
            setLoading(false);
        }
    };

    const handleVerify = async (id) => {
        try {
            await api.put(`/admin/users/${id}/verify`, null, { params: { type } });
            setUsers(users.map(user => user._id === id ? { ...user, isVerified: !user.isVerified } : user));
        } catch (error) {
            console.error("Verify failed", error);
        }
    };

    const handleDelete = async (id) => {
        if (!window.confirm("Are you sure?")) return;
        try {
            await api.delete(`/admin/users/${id}`, { params: { type } });
            setUsers(users.filter(user => user._id !== id));
        } catch (error) {
            console.error("Delete failed", error);
        }
    };

    const filteredUsers = users.filter(user =>
        user.username.toLowerCase().includes(searchTerm.toLowerCase()) ||
        user.email.toLowerCase().includes(searchTerm.toLowerCase())
    );

    return (
        <div className="space-y-6">
            <div className="flex flex-col md:flex-row md:items-center justify-between gap-4">
                <div>
                    <h2 className="text-3xl font-bold text-white capitalize">{type}s Management</h2>
                    <p className="text-text-muted">Manage and verify {type} accounts.</p>
                </div>
                <div className="flex items-center gap-3">
                    <div className="relative">
                        <Input
                            placeholder="Search users..."
                            className="w-64 pl-10"
                            value={searchTerm}
                            onChange={(e) => setSearchTerm(e.target.value)}
                        />
                        <Search className="absolute left-3 top-3.5 w-4 h-4 text-text-muted" />
                    </div>
                    <Button variant="outline" className="px-4"><Filter size={18} /></Button>
                </div>
            </div>

            <motion.div
                initial={{ opacity: 0, y: 20 }}
                animate={{ opacity: 1, y: 0 }}
                className="card overflow-hidden"
            >
                <div className="overflow-x-auto">
                    <table className="w-full text-left">
                        <thead>
                            <tr className="border-b border-white/10 text-text-muted text-sm uppercase tracking-wider">
                                <th className="p-4">User</th>
                                <th className="p-4">Status</th>
                                <th className="p-4">Verification</th>
                                <th className="p-4">Joined</th>
                                <th className="p-4 text-right">Actions</th>
                            </tr>
                        </thead>
                        <tbody className="divide-y divide-white/5">
                            {loading ? (
                                <tr><td colSpan="5" className="p-8 text-center text-text-muted">Loading...</td></tr>
                            ) : filteredUsers.length === 0 ? (
                                <tr><td colSpan="5" className="p-8 text-center text-text-muted">No users found.</td></tr>
                            ) : (
                                filteredUsers.map((user) => (
                                    <tr key={user._id} className="hover:bg-white/5 transition-colors group">
                                        <td className="p-4">
                                            <div className="flex items-center gap-3">
                                                <div className="w-10 h-10 rounded-full bg-primary/20 flex items-center justify-center text-primary font-bold uppercase">
                                                    {user.username[0]}
                                                </div>
                                                <div>
                                                    <p className="font-bold text-white">{user.username}</p>
                                                    <p className="text-sm text-text-muted">{user.email}</p>
                                                </div>
                                            </div>
                                        </td>
                                        <td className="p-4">
                                            {user.profileCompleted ? (
                                                <span className="px-2 py-1 rounded-full text-xs bg-success/20 text-success border border-success/20">Active</span>
                                            ) : (
                                                <span className="px-2 py-1 rounded-full text-xs bg-warning/20 text-warning border border-warning/20">Pending</span>
                                            )}
                                        </td>
                                        <td className="p-4">
                                            {user.isVerified ? (
                                                <div className="flex items-center gap-2 text-secondary">
                                                    <CheckCircle size={16} />
                                                    <span className="text-sm">Verified</span>
                                                </div>
                                            ) : (
                                                <button
                                                    onClick={() => handleVerify(user._id)}
                                                    className="text-sm text-text-muted hover:text-white underline decoration-dashed"
                                                >
                                                    Verify Now
                                                </button>
                                            )}
                                        </td>
                                        <td className="p-4 text-text-muted text-sm">
                                            {new Date(user.createdAt || Date.now()).toLocaleDateString()}
                                        </td>
                                        <td className="p-4 text-right">
                                            <div className="flex items-center justify-end gap-2 opacity-0 group-hover:opacity-100 transition-opacity">
                                                <button className="p-2 hover:bg-white/10 rounded-lg text-text-muted hover:text-white"><Mail size={18} /></button>
                                                <button
                                                    onClick={() => handleDelete(user._id)}
                                                    className="p-2 hover:bg-danger/20 rounded-lg text-danger"
                                                >
                                                    <Trash2 size={18} />
                                                </button>
                                            </div>
                                        </td>
                                    </tr>
                                ))
                            )}
                        </tbody>
                    </table>
                </div>
            </motion.div>
        </div>
    );
};

export default UsersPage;
