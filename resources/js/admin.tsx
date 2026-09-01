import React, { FormEvent, useEffect, useState } from 'react';
import { createRoot } from 'react-dom/client';
import '../css/admin.css';

type Counts = { pending_reports:number; pending_verifications:number; pending_appeals:number; active_users:number };
type Actor = { id:string; email:string; role:'moderator'|'super_admin' };
type Report = { id:string; category:string; details:string|null };
type Verification = { id:string; type:string; status:string };
type UserSummary = { id:string; name:string|null; email:string|null; status:string; admin_role:string|null; profile_status:string|null; country_code:string|null };
type UserDetail = UserSummary & { preferred_locale:string; created_at:string; last_login_at:string|null; counts:{reports_received:number;reports_submitted:number;active_matches:number}; profile:null|{city_name:string|null;photos:Array<{id:string;position:number;moderation_status:string;visibility:string}>} };
type Audit = { id:string; action:string; admin:{email:string}; subject_type:string; reason:string|null; created_at:string };
type AdminAccount = { id:string; name:string|null; email:string; role:'moderator'|'super_admin'; status:string };
const csrf = () => document.querySelector<HTMLMetaElement>('meta[name="csrf-token"]')?.content ?? '';

async function api(path:string, options:RequestInit = {}) {
    const response = await fetch('/api/v1/admin' + path, {
        credentials: 'same-origin',
        headers: { Accept:'application/json', 'Content-Type':'application/json', 'X-CSRF-TOKEN':csrf() },
        ...options,
    });
    if (response.status === 401 || response.status === 403) throw new Error(response.status === 403 ? 'FORBIDDEN' : 'AUTH');
    if (! response.ok) throw new Error('REQUEST');
    return response.json();
}

async function decide(path:string, decision:string, field='decision') {
    const reason = window.prompt('Reason for this decision:');
    if (! reason) return false;
    await api(path, { method:'PUT', body:JSON.stringify({ [field]:decision, reason }) });
    return true;
}

function Login() {
    return <main className="login"><section className="card"><div className="brand">SOUL</div>
        <h1>Admin workspace</h1><p>Authorized team members only.</p>
        <form method="post" action="/admin/session"><input type="hidden" name="_token" value={csrf()} />
            <label>Email<input name="email" type="email" required /></label>
            <label>Password<input name="password" type="password" required /></label>
            <button>Sign in securely</button></form></section></main>;
}

function App() {
    const [counts,setCounts] = useState<Counts|null>(null);
    const [actor,setActor] = useState<Actor|null>(null);
    const [reports,setReports] = useState<Report[]>([]);
    const [cases,setCases] = useState<Verification[]>([]);
    const [users,setUsers] = useState<UserSummary[]>([]);
    const [audits,setAudits] = useState<Audit[]>([]);
    const [admins,setAdmins] = useState<AdminAccount[]>([]);
    const [selected,setSelected] = useState<UserDetail|null>(null);
    const [search,setSearch] = useState('');
    const [authorized,setAuthorized] = useState(true);
    const [notice,setNotice] = useState('');

    const loadUsers = async (query='') => {
        const result = await api('/users' + (query ? `?search=${encodeURIComponent(query)}` : ''));
        setUsers(result.data.users);
    };
    const loadAudits = async () => setAudits((await api('/audit-logs')).data.audit_logs);
    const loadAdmins = async () => setAdmins((await api('/admins')).data.admins);
    const loadDetail = async (id:string) => setSelected((await api('/users/'+id)).data.user);
    const reloadQueues = async () => {
        const [dashboard,reportData,caseData] = await Promise.all([api('/dashboard'),api('/reports'),api('/verifications')]);
        setCounts(dashboard.data.counts); setActor(dashboard.data.actor);
        setReports(reportData.data.reports); setCases(caseData.data.cases);
        return dashboard.data.actor as Actor;
    };
    useEffect(() => { (async () => {
        const current = await reloadQueues();
        await Promise.all([loadUsers(),loadAudits(),...(current.role==='super_admin' ? [loadAdmins()] : [])]);
    })().catch(error => error.message === 'AUTH' && setAuthorized(false)); }, []);

    const searchUsers = async (event:FormEvent) => { event.preventDefault(); await loadUsers(search); };
    const changeStatus = async (status:string) => {
        if (! selected || ! await decide('/users/'+selected.id+'/status',status,'status')) return;
        await Promise.all([loadUsers(search),loadDetail(selected.id),loadAudits(),reloadQueues()]);
        setNotice(`User status changed to ${status}.`);
    };
    const moderate = async (path:string, decision:string) => {
        if (! await decide(path,decision)) return;
        await Promise.all([reloadQueues(),loadAudits()]);
    };
    const createAdmin = async (event:FormEvent<HTMLFormElement>) => {
        event.preventDefault();
        const form = event.currentTarget;
        const data = Object.fromEntries(new FormData(form).entries()) as Record<string,string>;
        const reason = window.prompt('Reason for creating this admin account:');
        if (! reason) return;
        await api('/admins', { method:'POST', body:JSON.stringify({...data,password_confirmation:data.password,reason}) });
        form.reset(); await Promise.all([loadAdmins(),loadAudits()]); setNotice('Admin account created.');
    };
    const changeAdminRole = async (admin:AdminAccount, role:string) => {
        if (! await decide('/admins/'+admin.id+'/role',role,'role')) return;
        await Promise.all([loadAdmins(),loadAudits()]); setNotice('Admin role updated.');
    };
    const removeAdmin = async (admin:AdminAccount) => {
        const reason = window.prompt('Reason for removing admin access:');
        if (! reason) return;
        await api('/admins/'+admin.id, {method:'DELETE',body:JSON.stringify({reason})});
        await Promise.all([loadAdmins(),loadAudits()]); setNotice('Admin access removed.');
    };

    if (! authorized) return <Login />;
    if (! counts || ! actor) return <main className="loading">Loading secure workspace…</main>;
    return <div className="shell"><aside><div className="brand">SOUL</div><span>Operations</span>
        <nav><a href="#overview">Overview</a><a href="#users">Users</a>{actor.role==='super_admin'&&<a href="#admins">Admin access</a>}<a href="#reports">Reports</a><a href="#verification">Verification</a><a href="#audit">Audit log</a></nav>
        <div className="operator"><b>{actor.role.replaceAll('_',' ')}</b><small>{actor.email}</small></div>
        <form method="post" action="/admin/session"><input type="hidden" name="_token" value={csrf()} /><input type="hidden" name="_method" value="DELETE" /><button>Sign out</button></form></aside>
        <main><header id="overview"><div><small>SOUL OPERATIONS</small><h1>Safety command center</h1></div><span className="secure">● Secure session</span></header>
            {notice && <div className="notice">{notice}</div>}
            <section className="metrics">{Object.entries(counts).map(([key,value]) => <article key={key}><strong>{value}</strong><span>{key.replaceAll('_',' ')}</span></article>)}</section>
            <section className="panel" id="users"><div className="panel-title"><h2>User directory</h2><form className="search" onSubmit={searchUsers}><input value={search} onChange={e=>setSearch(e.target.value)} placeholder="Email, name or public ID" /><button>Search</button></form></div>
                <div className="admin-grid"><div>{users.length ? users.map(user => <button className="user-row" key={user.id} onClick={()=>loadDetail(user.id)}><span><b>{user.name || 'Unnamed user'}</b><small>{user.email || user.id}</small></span><em className={'status '+user.status}>{user.status}</em></button>) : <p className="empty">No users found.</p>}</div>
                    <div className="detail">{selected ? <><h3>{selected.name || 'Unnamed user'}</h3><p>{selected.email}</p><dl><dt>Account</dt><dd>{selected.status}</dd><dt>Profile</dt><dd>{selected.profile_status || 'none'}</dd><dt>Country</dt><dd>{selected.country_code || 'unknown'}</dd><dt>Reports received</dt><dd>{selected.counts.reports_received}</dd><dt>Active matches</dt><dd>{selected.counts.active_matches}</dd></dl>
                        {selected.profile?.photos?.length ? <div className="photo-states">{selected.profile.photos.map(photo=><span key={photo.id}>#{photo.position} {photo.moderation_status}</span>)}</div> : <p className="empty">No profile photos.</p>}
                        {actor.role==='super_admin' && <div className="actions"><button onClick={()=>changeStatus('active')}>Restore</button><button className="warning" onClick={()=>changeStatus('suspended')}>Suspend</button><button className="danger" onClick={()=>changeStatus('blocked')}>Block</button></div>}</> : <p className="empty">Select a user to inspect.</p>}</div></div></section>
            {actor.role==='super_admin' && <section className="panel" id="admins"><h2>Admin access</h2><div className="admin-grid"><div>{admins.map(admin=><div className="row" key={admin.id}><div><b>{admin.name || admin.email}</b><p>{admin.email} · {admin.role.replaceAll('_',' ')}</p></div>{admin.id!==actor.id&&<div className="actions"><button onClick={()=>changeAdminRole(admin,'moderator')}>Moderator</button><button onClick={()=>changeAdminRole(admin,'super_admin')}>Super admin</button><button className="danger" onClick={()=>removeAdmin(admin)}>Remove</button></div>}</div>)}</div>
                <form className="detail admin-form" onSubmit={createAdmin}><h3>Create admin</h3><label>Name<input name="name" required maxLength={120}/></label><label>Email<input name="email" type="email" required/></label><label>Temporary password<input name="password" type="password" required minLength={12}/></label><label>Role<select name="role" defaultValue="moderator"><option value="moderator">Moderator</option><option value="super_admin">Super admin</option></select></label><button>Create secure account</button></form></div></section>}
            <section className="panel" id="reports"><h2>Pending reports</h2>{reports.length ? reports.map(report => <div className="row" key={report.id}><div><b>{report.category.replaceAll('_',' ')}</b><p>{report.details || 'No additional details'}</p></div><div><button onClick={() => moderate('/reports/'+report.id,'resolved')}>Resolve</button> <button className="warning" onClick={() => moderate('/reports/'+report.id,'dismissed')}>Dismiss</button></div></div>) : <p className="empty">Queue is clear.</p>}</section>
            <section className="panel" id="verification"><h2>Verification queue</h2>{cases.length ? cases.map(item => <div className="row" key={item.id}><div><b>{item.type.replaceAll('_',' ')}</b><p>{item.status.replaceAll('_',' ')}</p></div><div><button onClick={() => moderate('/verifications/'+item.id,'approved')}>Approve</button> <button className="warning" onClick={() => moderate('/verifications/'+item.id,'appeal_available')}>Correction</button></div></div>) : <p className="empty">Queue is clear.</p>}</section>
            <section className="panel" id="audit"><h2>Immutable audit log</h2>{audits.length ? audits.map(log=><div className="row audit" key={log.id}><div><b>{log.action.replaceAll('.',' ')}</b><p>{log.subject_type} · {log.reason || 'No reason recorded'}</p></div><div><small>{log.admin.email}</small><time>{new Date(log.created_at).toLocaleString()}</time></div></div>) : <p className="empty">No audit events.</p>}</section>
        </main></div>;
}
createRoot(document.getElementById('admin-root')!).render(<React.StrictMode><App /></React.StrictMode>);
