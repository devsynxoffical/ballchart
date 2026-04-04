import React, { useEffect, useMemo, useState } from 'react';
import { CheckCircle2, Trash2 } from 'lucide-react';
import api from '../services/api';
import { Button } from '../components/ui/Button';
import { Input } from '../components/ui/Input';
import { toast } from 'react-hot-toast';

const RoleBadge = ({ role }) => {
    const roleLabel = (role || '').replaceAll('_', ' ') || 'unknown';
    return (
        <span className="px-2 py-1 rounded-full text-xs bg-white/10 border border-white/10 text-white/80 capitalize">
            {roleLabel}
        </span>
    );
};

const StatusPill = ({ verified }) => (
    <span
        className={`px-2 py-1 rounded-full text-xs border ${verified
            ? 'bg-success/20 border-success/40 text-success'
            : 'bg-warning/20 border-warning/40 text-warning'
            }`}
    >
        {verified ? 'Verified' : 'Unverified'}
    </span>
);

const AcademyUsersTable = ({ title, type, academyId, users, onRefresh }) => {
    const [loadingActionId, setLoadingActionId] = useState(null);

    const handleVerify = async (userId) => {
        try {
            setLoadingActionId(userId);
            await api.put(`/admin/users/${userId}/verify`, null, {
                params: { type, academyId },
            });
            toast.success(`${type === 'coach' ? 'Staff' : 'Player'} verification updated`);
            onRefresh();
        } catch (error) {
            toast.error(error.response?.data?.message || 'Failed to update verification');
        } finally {
            setLoadingActionId(null);
        }
    };

    const handleDelete = async (userId) => {
        const ok = window.confirm('Delete this user? This action cannot be undone.');
        if (!ok) return;

        try {
            setLoadingActionId(userId);
            await api.delete(`/admin/users/${userId}`, {
                params: { type, academyId },
            });
            toast.success(`${type === 'coach' ? 'Staff' : 'Player'} deleted`);
            onRefresh();
        } catch (error) {
            toast.error(error.response?.data?.message || 'Failed to delete user');
        } finally {
            setLoadingActionId(null);
        }
    };

    return (
        <div className="card">
            <div className="flex items-center justify-between mb-4">
                <h3 className="text-lg font-bold text-white">{title}</h3>
                <span className="text-sm text-text-muted">{users.length} total</span>
            </div>

            {users.length === 0 ? (
                <p className="text-text-muted">No records found.</p>
            ) : (
                <div className="overflow-x-auto">
                    <table className="w-full text-left">
                        <thead>
                            <tr className="text-text-muted text-xs uppercase border-b border-white/10">
                                <th className="py-3 pr-4">Name</th>
                                <th className="py-3 pr-4">Email</th>
                                <th className="py-3 pr-4">Role</th>
                                <th className="py-3 pr-4">Status</th>
                                <th className="py-3 text-right">Actions</th>
                            </tr>
                        </thead>
                        <tbody className="divide-y divide-white/5">
                            {users.map((user) => (
                                <tr key={user._id}>
                                    <td className="py-3 pr-4 text-white">{user.username}</td>
                                    <td className="py-3 pr-4 text-white/70">{user.email}</td>
                                    <td className="py-3 pr-4"><RoleBadge role={user.role} /></td>
                                    <td className="py-3 pr-4"><StatusPill verified={user.isVerified} /></td>
                                    <td className="py-3 text-right">
                                        <div className="inline-flex gap-2">
                                            <Button
                                                variant="outline"
                                                className="px-3 py-2"
                                                onClick={() => handleVerify(user._id)}
                                                isLoading={loadingActionId === user._id}
                                            >
                                                <CheckCircle2 size={14} />
                                                Verify
                                            </Button>
                                            <Button
                                                className="px-3 py-2 bg-danger text-white hover:bg-danger/90"
                                                onClick={() => handleDelete(user._id)}
                                                isLoading={loadingActionId === user._id}
                                            >
                                                <Trash2 size={14} />
                                                Delete
                                            </Button>
                                        </div>
                                    </td>
                                </tr>
                            ))}
                        </tbody>
                    </table>
                </div>
            )}
        </div>
    );
};

const AcademiesPage = () => {
    const [academies, setAcademies] = useState([]);
    const [selectedAcademyId, setSelectedAcademyId] = useState('');
    const [academyDetail, setAcademyDetail] = useState(null);
    const [loading, setLoading] = useState(true);
    const [detailLoading, setDetailLoading] = useState(false);
    const [savingProfile, setSavingProfile] = useState(false);
    const [statusActionLoading, setStatusActionLoading] = useState(false);
    const [deletingAcademy, setDeletingAcademy] = useState(false);
    const [deletingTeamId, setDeletingTeamId] = useState(null);
    const [profileForm, setProfileForm] = useState({
        academyName: '',
        username: '',
        email: '',
        logoUrl: '',
    });

    const fetchAcademies = async () => {
        const response = await api.get('/admin/academies');
        setAcademies(response.data || []);
        return response.data || [];
    };

    const fetchAcademyDetail = async (academyId) => {
        if (!academyId) return;
        setDetailLoading(true);
        try {
            const response = await api.get(`/admin/academies/${academyId}`);
            setAcademyDetail(response.data);
            setProfileForm({
                academyName: response.data.academy?.academyName || '',
                username: response.data.academy?.username || '',
                email: response.data.academy?.email || '',
                logoUrl: response.data.academy?.logoUrl || '',
            });
        } catch (error) {
            toast.error(error.response?.data?.message || 'Failed to load academy detail');
        } finally {
            setDetailLoading(false);
        }
    };

    const refreshSelectedAcademy = async (academyId = selectedAcademyId) => {
        await fetchAcademyDetail(academyId);
        await fetchAcademies();
    };

    useEffect(() => {
        const bootstrap = async () => {
            setLoading(true);
            try {
                const list = await fetchAcademies();
                if (list.length > 0) {
                    const firstId = list[0]._id;
                    setSelectedAcademyId(firstId);
                    await fetchAcademyDetail(firstId);
                }
            } catch (error) {
                toast.error(error.response?.data?.message || 'Failed to load academies');
            } finally {
                setLoading(false);
            }
        };

        bootstrap();
    }, []);

    const selectedAcademy = useMemo(
        () => academies.find((academy) => academy._id === selectedAcademyId) || null,
        [academies, selectedAcademyId]
    );
    const pendingAcademies = useMemo(
        () => academies.filter((academy) => academy.approvalStatus === 'pending'),
        [academies]
    );

    const handleAcademyChange = async (event) => {
        const academyId = event.target.value;
        setSelectedAcademyId(academyId);
        await fetchAcademyDetail(academyId);
    };

    const handleSaveAcademyProfile = async () => {
        if (!selectedAcademyId) return;
        setSavingProfile(true);
        try {
            await api.put(`/admin/academies/${selectedAcademyId}`, profileForm);
            toast.success('Academy profile updated');
            await refreshSelectedAcademy();
        } catch (error) {
            toast.error(error.response?.data?.message || 'Failed to update academy profile');
        } finally {
            setSavingProfile(false);
        }
    };

    const handleDeleteTeam = async (teamId) => {
        const ok = window.confirm('Delete this team?');
        if (!ok || !selectedAcademyId) return;

        setDeletingTeamId(teamId);
        try {
            await api.delete(`/admin/academies/${selectedAcademyId}/teams/${teamId}`);
            toast.success('Team deleted');
            await refreshSelectedAcademy();
        } catch (error) {
            toast.error(error.response?.data?.message || 'Failed to delete team');
        } finally {
            setDeletingTeamId(null);
        }
    };

    const handleAcademyStatusAction = async (action) => {
        if (!selectedAcademyId) return;
        setStatusActionLoading(true);
        try {
            await api.put(`/admin/academies/${selectedAcademyId}/status`, { action });
            toast.success(`Academy action "${action}" applied`);
            await refreshSelectedAcademy();
        } catch (error) {
            toast.error(error.response?.data?.message || 'Failed to update academy status');
        } finally {
            setStatusActionLoading(false);
        }
    };

    const handleDeleteAcademy = async () => {
        if (!selectedAcademyId) return;
        const ok = window.confirm('Delete this academy and all related data (teams, staff, players)?');
        if (!ok) return;

        setDeletingAcademy(true);
        try {
            await api.delete(`/admin/academies/${selectedAcademyId}`);
            toast.success('Academy deleted');
            const refreshed = await fetchAcademies();
            if (refreshed.length > 0) {
                const nextAcademyId = refreshed[0]._id;
                setSelectedAcademyId(nextAcademyId);
                await fetchAcademyDetail(nextAcademyId);
            } else {
                setSelectedAcademyId('');
                setAcademyDetail(null);
            }
        } catch (error) {
            toast.error(error.response?.data?.message || 'Failed to delete academy');
        } finally {
            setDeletingAcademy(false);
        }
    };

    if (loading) {
        return <div className="text-text-muted">Loading academies...</div>;
    }

    return (
        <div className="space-y-6">
            <div className="card">
                <div className="flex flex-col lg:flex-row gap-4 lg:items-end">
                    <div className="w-full lg:max-w-sm">
                        <label className="text-xs uppercase text-text-muted tracking-wider mb-2 block">
                            Select Academy
                        </label>
                        <select
                            value={selectedAcademyId}
                            onChange={handleAcademyChange}
                            className="w-full px-4 py-3 bg-surface/50 border border-white/10 rounded-xl text-white"
                        >
                            {academies.map((academy) => (
                                <option key={academy._id} value={academy._id}>
                                    {academy.academyName}
                                </option>
                            ))}
                        </select>
                    </div>
                    <div className="text-text-muted text-sm">
                        Manage academy profile, teams, coaches, assistant coaches, and players.
                    </div>
                </div>
            </div>

            <div className="card">
                <h3 className="text-lg font-bold text-white mb-3">Pending Signup Requests</h3>
                {pendingAcademies.length === 0 ? (
                    <p className="text-text-muted">No pending academy requests.</p>
                ) : (
                    <div className="space-y-2">
                        {pendingAcademies.map((academy) => (
                            <div key={academy._id} className="flex flex-col lg:flex-row lg:items-center justify-between gap-3 p-3 rounded-xl bg-surface/40 border border-white/10">
                                <div>
                                    <p className="text-white font-semibold">{academy.academyName}</p>
                                    <p className="text-text-muted text-sm">{academy.email}</p>
                                </div>
                                <div className="inline-flex gap-2">
                                    <Button
                                        className="px-3 py-2"
                                        onClick={async () => {
                                            setSelectedAcademyId(academy._id);
                                            await api.put(`/admin/academies/${academy._id}/status`, { action: 'approve' });
                                            toast.success('Academy approved');
                                            await refreshSelectedAcademy(academy._id);
                                        }}
                                    >
                                        Approve
                                    </Button>
                                    <Button
                                        className="px-3 py-2 bg-danger text-white hover:bg-danger/90"
                                        onClick={async () => {
                                            await api.put(`/admin/academies/${academy._id}/status`, { action: 'reject' });
                                            toast.success('Academy rejected');
                                            await refreshSelectedAcademy(academy._id);
                                        }}
                                    >
                                        Reject
                                    </Button>
                                </div>
                            </div>
                        ))}
                    </div>
                )}
            </div>

            {detailLoading || !academyDetail ? (
                <div className="text-text-muted">Loading academy details...</div>
            ) : (
                <>
                    <div className="grid grid-cols-1 md:grid-cols-4 gap-4">
                        <div className="card">
                            <p className="text-text-muted text-sm">Academy</p>
                            <p className="text-white text-xl font-bold mt-1">{academyDetail.academy?.academyName}</p>
                            <p className="text-xs mt-2 text-white/70">
                                Status: {academyDetail.academy?.approvalStatus || 'approved'}
                                {academyDetail.academy?.isTempBanned ? ' • temp banned' : ''}
                                {academyDetail.academy?.isStopped ? ' • stopped' : ''}
                            </p>
                        </div>
                        <div className="card">
                            <p className="text-text-muted text-sm">Teams</p>
                            <p className="text-white text-xl font-bold mt-1">{academyDetail.stats?.teams || 0}</p>
                        </div>
                        <div className="card">
                            <p className="text-text-muted text-sm">Staff</p>
                            <p className="text-white text-xl font-bold mt-1">{academyDetail.stats?.staff || 0}</p>
                        </div>
                        <div className="card">
                            <p className="text-text-muted text-sm">Players</p>
                            <p className="text-white text-xl font-bold mt-1">{academyDetail.stats?.players || 0}</p>
                        </div>
                    </div>

                    <div className="card space-y-4">
                        <h3 className="text-lg font-bold text-white">Academy Profile</h3>
                        <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                            <Input
                                label="Academy Name"
                                value={profileForm.academyName}
                                onChange={(event) => setProfileForm((prev) => ({ ...prev, academyName: event.target.value }))}
                            />
                            <Input
                                label="Owner Name"
                                value={profileForm.username}
                                onChange={(event) => setProfileForm((prev) => ({ ...prev, username: event.target.value }))}
                            />
                            <Input
                                label="Owner Email"
                                type="email"
                                value={profileForm.email}
                                onChange={(event) => setProfileForm((prev) => ({ ...prev, email: event.target.value }))}
                            />
                            <Input
                                label="Logo URL"
                                value={profileForm.logoUrl}
                                onChange={(event) => setProfileForm((prev) => ({ ...prev, logoUrl: event.target.value }))}
                            />
                        </div>
                        <div className="flex justify-end">
                            <Button onClick={handleSaveAcademyProfile} isLoading={savingProfile}>
                                Save Academy Profile
                            </Button>
                        </div>
                    </div>

                    <div className="card space-y-4">
                        <h3 className="text-lg font-bold text-white">Academy Access Controls</h3>
                        <div className="flex flex-wrap gap-2">
                            <Button variant="outline" onClick={() => handleAcademyStatusAction('approve')} isLoading={statusActionLoading}>
                                Approve
                            </Button>
                            <Button variant="outline" onClick={() => handleAcademyStatusAction('temp_ban')} isLoading={statusActionLoading}>
                                Temp Ban
                            </Button>
                            <Button variant="outline" onClick={() => handleAcademyStatusAction('untemp_ban')} isLoading={statusActionLoading}>
                                Remove Temp Ban
                            </Button>
                            <Button variant="outline" onClick={() => handleAcademyStatusAction('stop')} isLoading={statusActionLoading}>
                                Stop
                            </Button>
                            <Button variant="outline" onClick={() => handleAcademyStatusAction('unstop')} isLoading={statusActionLoading}>
                                Restart
                            </Button>
                            <Button className="bg-danger text-white hover:bg-danger/90" onClick={handleDeleteAcademy} isLoading={deletingAcademy}>
                                Delete Academy
                            </Button>
                        </div>
                    </div>

                    <div className="card">
                        <div className="flex items-center justify-between mb-4">
                            <h3 className="text-lg font-bold text-white">Teams</h3>
                            <span className="text-text-muted text-sm">{academyDetail.teams.length} total</span>
                        </div>
                        {academyDetail.teams.length === 0 ? (
                            <p className="text-text-muted">No teams in this academy.</p>
                        ) : (
                            <div className="space-y-3">
                                {academyDetail.teams.map((team) => (
                                    <div key={team._id} className="p-4 rounded-xl border border-white/10 bg-surface/40">
                                        <div className="flex flex-col lg:flex-row lg:items-center justify-between gap-3">
                                            <div>
                                                <p className="text-white font-semibold">{team.name}</p>
                                                <p className="text-text-muted text-sm">
                                                    {team.ageGroup || 'Open'} • {team.players?.length || 0} players
                                                </p>
                                                <p className="text-text-muted text-sm mt-1">
                                                    Coach: {team.coachStaffId?.username || 'Not assigned'} | Assistant: {team.assistantCoachStaffId?.username || 'Not assigned'}
                                                </p>
                                            </div>
                                            <Button
                                                className="px-3 py-2 bg-danger text-white hover:bg-danger/90"
                                                onClick={() => handleDeleteTeam(team._id)}
                                                isLoading={deletingTeamId === team._id}
                                            >
                                                <Trash2 size={14} />
                                                Delete Team
                                            </Button>
                                        </div>
                                    </div>
                                ))}
                            </div>
                        )}
                    </div>

                    <AcademyUsersTable
                        title="Coaches & Assistant Coaches"
                        type="coach"
                        academyId={selectedAcademyId}
                        users={academyDetail.staff || []}
                        onRefresh={refreshSelectedAcademy}
                    />

                    <AcademyUsersTable
                        title="Players"
                        type="player"
                        academyId={selectedAcademyId}
                        users={academyDetail.players || []}
                        onRefresh={refreshSelectedAcademy}
                    />
                </>
            )}

            {!selectedAcademy && (
                <div className="card text-text-muted">No academy selected.</div>
            )}
        </div>
    );
};

export default AcademiesPage;
