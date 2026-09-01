import React, { useEffect, useState } from 'react';
import { createRoot } from 'react-dom/client';
import '../css/admin.css';

type Counts = { pending_reports:number; pending_verifications:number; pending_appeals:number; active_users:number };
type Report = { id:string; category:string; details:string|null };
type Verification = { id:string; type:string; status:string };
const csrf = () => document.querySelector<HTMLMetaElement>('meta[name="csrf-token"]')?.content ?? '';
async function api(path:string, options:RequestInit = {}) {
    const response = await fetch('/api/v1/admin' + path, {
        credentials: 'same-origin',
        headers: { Accept:'application/json', 'Content-Type':'application/json', 'X-CSRF-TOKEN':csrf() },
        ...options,
    });
    if (response.status === 401 || response.status === 403) throw new Error('AUTH');
    if (! response.ok) throw new Error('REQUEST');
    return response.json();
}
async function decide(path:string, decision:string) {
    const reason = window.prompt('Reason for this decision:');
    if (! reason) return;
    await api(path, { method:'PUT', body:JSON.stringify({ decision, reason }) });
    window.location.reload();
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
    const [reports,setReports] = useState<Report[]>([]);
    const [cases,setCases] = useState<Verification[]>([]);
    const [authorized,setAuthorized] = useState(true);
    useEffect(() => { Promise.all([api('/dashboard'),api('/reports'),api('/verifications')])
        .then(([dashboard,reportData,caseData]) => { setCounts(dashboard.data.counts); setReports(reportData.data.reports); setCases(caseData.data.cases); })
        .catch(error => error.message === 'AUTH' && setAuthorized(false)); }, []);
    if (! authorized) return <Login />;
    if (! counts) return <main className="loading">Loading secure workspace…</main>;
    return <div className="shell"><aside><div className="brand">SOUL</div><span>Operations</span>
        <nav><b>Overview</b><a href="#reports">Reports</a><a href="#verification">Verification</a></nav>
        <form method="post" action="/admin/session"><input type="hidden" name="_token" value={csrf()} />
            <input type="hidden" name="_method" value="DELETE" /><button>Sign out</button></form></aside>
        <main><header><div><small>SOUL OPERATIONS</small><h1>Safety command center</h1></div><span className="secure">● Secure session</span></header>
            <section className="metrics">{Object.entries(counts).map(([key,value]) => <article key={key}><strong>{value}</strong><span>{key.replaceAll('_',' ')}</span></article>)}</section>
            <section className="panel" id="reports"><h2>Pending reports</h2>{reports.length ? reports.map(report =>
                <div className="row" key={report.id}><div><b>{report.category.replaceAll('_',' ')}</b><p>{report.details || 'No additional details'}</p></div>
                    <div><button onClick={() => decide('/reports/'+report.id,'resolved')}>Resolve</button> <button onClick={() => decide('/reports/'+report.id,'dismissed')}>Dismiss</button></div></div>) : <p className="empty">Queue is clear.</p>}</section>
            <section className="panel" id="verification"><h2>Verification queue</h2>{cases.length ? cases.map(item =>
                <div className="row" key={item.id}><div><b>{item.type.replaceAll('_',' ')}</b><p>{item.status.replaceAll('_',' ')}</p></div>
                    <div><button onClick={() => decide('/verifications/'+item.id,'approved')}>Approve</button> <button onClick={() => decide('/verifications/'+item.id,'appeal_available')}>Correction</button></div></div>) : <p className="empty">Queue is clear.</p>}</section>
        </main></div>;
}
createRoot(document.getElementById('admin-root')!).render(<React.StrictMode><App /></React.StrictMode>);
