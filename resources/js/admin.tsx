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
type ReligionNode = { id:string; parent_id:string|null; type:string; slug:string; path:string; is_active:boolean; sort_order:number; translations:Array<{locale:string;label:string;description:string|null}>; country_codes:string[] };
type Broadcast = { id:string; title:string; body:string; category:string; audience_type:string; audience_value:string|null; status:string; estimated_recipients:number; delivered_count:number; read_count:number };
type Messages = Record<string,string>;
type Translate = (key:string) => string;
const csrf = () => document.querySelector<HTMLMetaElement>('meta[name="csrf-token"]')?.content ?? '';

function useLocalization() {
    const [locale,setLocaleState] = useState(() => localStorage.getItem('soul.admin.locale') || 'en');
    const [messages,setMessages] = useState<Messages>({});
    const t:Translate = key => messages[key] || key;
    const setLocale = (value:string) => { localStorage.setItem('soul.admin.locale',value); setLocaleState(value); };

    useEffect(() => { fetch('/api/v1/bootstrap?locale='+encodeURIComponent(locale), {headers:{Accept:'application/json'}})
        .then(response => response.ok ? response.json() : Promise.reject())
        .then(result => { setMessages(result.data.translations.values); document.documentElement.lang=result.data.locale.resolved; document.documentElement.dir=result.data.locale.direction; })
        .catch(() => setMessages({})); }, [locale]);

    return {locale,setLocale,t,ready:Object.keys(messages).length > 0};
}

function LanguageSwitch({locale,setLocale,t}:{locale:string;setLocale:(locale:string)=>void;t:Translate}) {
    return <label className="locale-switch">{t('admin.language')}<select value={locale} onChange={event=>setLocale(event.target.value)}>
        <option value="en">{t('admin.english')}</option><option value="ur">{t('admin.roman_urdu')}</option>
    </select></label>;
}

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

async function decide(path:string, decision:string, t:Translate, field='decision') {
    const reason = window.prompt(t('admin.prompt_decision_reason'));
    if (! reason) return false;
    await api(path, { method:'PUT', body:JSON.stringify({ [field]:decision, reason }) });
    return true;
}

function Login({locale,setLocale,t}:{locale:string;setLocale:(locale:string)=>void;t:Translate}) {
    return <main className="login"><section className="card"><div className="brand">SOUL</div>
        <LanguageSwitch locale={locale} setLocale={setLocale} t={t}/>
        <h1>{t('admin.workspace')}</h1><p>{t('admin.authorized_only')}</p>
        <form method="post" action="/admin/session"><input type="hidden" name="_token" value={csrf()} />
            <label>{t('admin.email')}<input name="email" type="email" required /></label>
            <label>{t('admin.password')}<input name="password" type="password" required /></label>
            <button>{t('admin.sign_in')}</button></form></section></main>;
}

function App() {
    const {locale,setLocale,t,ready} = useLocalization();
    const [counts,setCounts] = useState<Counts|null>(null);
    const [actor,setActor] = useState<Actor|null>(null);
    const [reports,setReports] = useState<Report[]>([]);
    const [cases,setCases] = useState<Verification[]>([]);
    const [users,setUsers] = useState<UserSummary[]>([]);
    const [audits,setAudits] = useState<Audit[]>([]);
    const [admins,setAdmins] = useState<AdminAccount[]>([]);
    const [religionNodes,setReligionNodes] = useState<ReligionNode[]>([]);
    const [broadcasts,setBroadcasts] = useState<Broadcast[]>([]);
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
    const loadReligion = async () => setReligionNodes((await api('/religion-taxonomy')).data.nodes);
    const loadBroadcasts = async () => setBroadcasts((await api('/notification-broadcasts')).data.broadcasts);
    const loadDetail = async (id:string) => setSelected((await api('/users/'+id)).data.user);
    const reloadQueues = async () => {
        const [dashboard,reportData,caseData] = await Promise.all([api('/dashboard'),api('/reports'),api('/verifications')]);
        setCounts(dashboard.data.counts); setActor(dashboard.data.actor);
        setReports(reportData.data.reports); setCases(caseData.data.cases);
        return dashboard.data.actor as Actor;
    };
    useEffect(() => { (async () => {
        const current = await reloadQueues();
        await Promise.all([loadUsers(),loadAudits(),...(current.role==='super_admin' ? [loadAdmins(),loadReligion(),loadBroadcasts()] : [])]);
    })().catch(error => error.message === 'AUTH' && setAuthorized(false)); }, []);

    const searchUsers = async (event:FormEvent) => { event.preventDefault(); await loadUsers(search); };
    const changeStatus = async (status:string) => {
        if (! selected || ! await decide('/users/'+selected.id+'/status',status,t,'status')) return;
        await Promise.all([loadUsers(search),loadDetail(selected.id),loadAudits(),reloadQueues()]);
        setNotice(t('admin.notice_status_changed'));
    };
    const moderate = async (path:string, decision:string) => {
        if (! await decide(path,decision,t)) return;
        await Promise.all([reloadQueues(),loadAudits()]);
    };
    const createAdmin = async (event:FormEvent<HTMLFormElement>) => {
        event.preventDefault();
        const form = event.currentTarget;
        const data = Object.fromEntries(new FormData(form).entries()) as Record<string,string>;
        const reason = window.prompt(t('admin.prompt_create_admin'));
        if (! reason) return;
        await api('/admins', { method:'POST', body:JSON.stringify({...data,password_confirmation:data.password,reason}) });
        form.reset(); await Promise.all([loadAdmins(),loadAudits()]); setNotice(t('admin.notice_admin_created'));
    };
    const changeAdminRole = async (admin:AdminAccount, role:string) => {
        if (! await decide('/admins/'+admin.id+'/role',role,t,'role')) return;
        await Promise.all([loadAdmins(),loadAudits()]); setNotice(t('admin.notice_role_updated'));
    };
    const removeAdmin = async (admin:AdminAccount) => {
        const reason = window.prompt(t('admin.prompt_remove_admin'));
        if (! reason) return;
        await api('/admins/'+admin.id, {method:'DELETE',body:JSON.stringify({reason})});
        await Promise.all([loadAdmins(),loadAudits()]); setNotice(t('admin.notice_admin_removed'));
    };
    const saveReligion = async (event:FormEvent<HTMLFormElement>) => {
        event.preventDefault(); const form=event.currentTarget;
        const data=Object.fromEntries(new FormData(form).entries()) as Record<string,string>;
        const reason=window.prompt(t('admin.prompt_taxonomy')); if(!reason)return;
        await api('/religion-taxonomy',{method:'POST',body:JSON.stringify({parent_id:data.parent_id||null,type:data.type,slug:data.slug,is_active:true,sort_order:Number(data.sort_order||0),translations:[{locale:'en',label:data.label,description:null}],country_codes:data.country_codes?data.country_codes.split(',').map(value=>value.trim().toUpperCase()).filter(Boolean):[],reason})});
        form.reset(); await Promise.all([loadReligion(),loadAudits()]); setNotice(t('admin.notice_taxonomy_created'));
    };
    const toggleReligion = async (node:ReligionNode) => {
        const reason=window.prompt(t('admin.prompt_taxonomy')); if(!reason)return;
        await api('/religion-taxonomy/'+node.id,{method:'PUT',body:JSON.stringify({...node,is_active:!node.is_active,translations:node.translations,country_codes:node.country_codes,reason})});
        await Promise.all([loadReligion(),loadAudits()]); setNotice(t('admin.notice_taxonomy_updated'));
    };
    const createBroadcast = async (event:FormEvent<HTMLFormElement>) => { event.preventDefault(); const form=event.currentTarget; const data=Object.fromEntries(new FormData(form).entries()) as Record<string,string>; const reason=window.prompt(t('admin.prompt_broadcast')); if(!reason)return; await api('/notification-broadcasts',{method:'POST',body:JSON.stringify({...data,audience_value:data.audience_value||null,reason})}); form.reset(); await Promise.all([loadBroadcasts(),loadAudits()]); setNotice(t('admin.notice_draft_created')); };
    const sendBroadcast = async (item:Broadcast) => { if(!window.confirm(`${t('admin.review_send')}: ${item.title}?`))return; const reason=window.prompt(t('admin.prompt_send')); if(!reason)return; await api('/notification-broadcasts/'+item.id+'/send',{method:'POST',body:JSON.stringify({confirmation:'SEND',reason})}); await Promise.all([loadBroadcasts(),loadAudits()]); setNotice(t('admin.notice_broadcast_queued')); };

    const valueLabel = (value:string) => { const key='admin.value.'+value; const translated=t(key); return translated===key ? value.replaceAll('_',' ') : translated; };
    if (! ready) return <main className="loading"><div className="brand">SOUL</div></main>;
    if (! authorized) return <Login locale={locale} setLocale={setLocale} t={t} />;
    if (! counts || ! actor) return <main className="loading">{t('admin.loading')}</main>;
    return <div className="shell"><aside><div className="brand">SOUL</div><span>{t('admin.operations')}</span>
        <nav><a href="#overview">{t('admin.overview')}</a><a href="#users">{t('admin.users')}</a>{actor.role==='super_admin'&&<><a href="#admins">{t('admin.admin_access')}</a><a href="#religion">{t('admin.religion_taxonomy')}</a><a href="#broadcasts">{t('admin.broadcasts')}</a></>}<a href="#reports">{t('admin.reports')}</a><a href="#verification">{t('admin.verification')}</a><a href="#audit">{t('admin.audit_log')}</a></nav>
        <LanguageSwitch locale={locale} setLocale={setLocale} t={t}/><div className="operator"><b>{valueLabel(actor.role)}</b><small>{actor.email}</small></div>
        <form method="post" action="/admin/session"><input type="hidden" name="_token" value={csrf()} /><input type="hidden" name="_method" value="DELETE" /><button>{t('admin.sign_out')}</button></form></aside>
        <main><header id="overview"><div><small>SOUL {t('admin.operations').toUpperCase()}</small><h1>{t('admin.command_center')}</h1></div><span className="secure">● {t('admin.secure_session')}</span></header>
            {notice && <div className="notice">{notice}</div>}
            <section className="metrics">{Object.entries(counts).map(([key,value]) => <article key={key}><strong>{value}</strong><span>{valueLabel(key)}</span></article>)}</section>
            <section className="panel" id="users"><div className="panel-title"><h2>{t('admin.user_directory')}</h2><form className="search" onSubmit={searchUsers}><input value={search} onChange={e=>setSearch(e.target.value)} placeholder={t('admin.search_placeholder')} /><button>{t('common.search')}</button></form></div>
                <div className="admin-grid"><div>{users.length ? users.map(user => <button className="user-row" key={user.id} onClick={()=>loadDetail(user.id)}><span><b>{user.name || t('admin.unnamed_user')}</b><small>{user.email || user.id}</small></span><em className={'status '+user.status}>{valueLabel(user.status)}</em></button>) : <p className="empty">{t('admin.no_users')}</p>}</div>
                    <div className="detail">{selected ? <><h3>{selected.name || t('admin.unnamed_user')}</h3><p>{selected.email}</p><dl><dt>{t('admin.account')}</dt><dd>{valueLabel(selected.status)}</dd><dt>{t('admin.profile')}</dt><dd>{valueLabel(selected.profile_status || 'none')}</dd><dt>{t('admin.country')}</dt><dd>{selected.country_code || valueLabel('unknown')}</dd><dt>{t('admin.reports_received')}</dt><dd>{selected.counts.reports_received}</dd><dt>{t('admin.active_matches')}</dt><dd>{selected.counts.active_matches}</dd></dl>
                        {selected.profile?.photos?.length ? <div className="photo-states">{selected.profile.photos.map(photo=><span key={photo.id}>#{photo.position} {valueLabel(photo.moderation_status)}</span>)}</div> : <p className="empty">{t('admin.no_photos')}</p>}
                        {actor.role==='super_admin' && <div className="actions"><button onClick={()=>changeStatus('active')}>{t('admin.restore')}</button><button className="warning" onClick={()=>changeStatus('suspended')}>{t('admin.suspend')}</button><button className="danger" onClick={()=>changeStatus('blocked')}>{t('admin.block')}</button></div>}</> : <p className="empty">{t('admin.select_user')}</p>}</div></div></section>
            {actor.role==='super_admin' && <section className="panel" id="admins"><h2>{t('admin.admin_access')}</h2><div className="admin-grid"><div>{admins.map(admin=><div className="row" key={admin.id}><div><b>{admin.name || admin.email}</b><p>{admin.email} · {valueLabel(admin.role)}</p></div>{admin.id!==actor.id&&<div className="actions"><button onClick={()=>changeAdminRole(admin,'moderator')}>{t('admin.moderator')}</button><button onClick={()=>changeAdminRole(admin,'super_admin')}>{t('admin.super_admin')}</button><button className="danger" onClick={()=>removeAdmin(admin)}>{t('admin.remove')}</button></div>}</div>)}</div>
                <form className="detail admin-form" onSubmit={createAdmin}><h3>{t('admin.create_admin')}</h3><label>{t('admin.name')}<input name="name" required maxLength={120}/></label><label>{t('admin.email')}<input name="email" type="email" required/></label><label>{t('admin.temporary_password')}<input name="password" type="password" required minLength={12}/></label><label>{t('admin.role')}<select name="role" defaultValue="moderator"><option value="moderator">{t('admin.moderator')}</option><option value="super_admin">{t('admin.super_admin')}</option></select></label><button>{t('admin.create_account')}</button></form></div></section>}
            {actor.role==='super_admin' && <section className="panel" id="religion"><h2>{t('admin.taxonomy_translations')}</h2><div className="admin-grid"><div>{religionNodes.map(node=><div className="row" key={node.id}><div><b>{node.translations.find(t=>t.locale===locale)?.label||node.translations.find(t=>t.locale==='en')?.label||node.slug}</b><p>{node.path} · {node.country_codes.length?node.country_codes.join(', '):t('admin.global')} · {node.is_active?t('admin.active'):t('admin.inactive')}</p></div><button className={node.is_active?'warning':''} onClick={()=>toggleReligion(node)}>{node.is_active?t('admin.deactivate'):t('admin.activate')}</button></div>)}</div><form className="detail admin-form" onSubmit={saveReligion}><h3>{t('admin.add_taxonomy')}</h3><label>{t('admin.english_label')}<input name="label" required maxLength={120}/></label><label>{t('admin.slug')}<input name="slug" required pattern="[A-Za-z0-9_-]+"/></label><label>{t('admin.type')}<select name="type">{['religion','belief','sect','tradition','denomination','sub_sect','school','movement','community','caste'].map(type=><option key={type} value={type}>{valueLabel(type)}</option>)}</select></label><label>{t('admin.parent')}<select name="parent_id"><option value="">{t('admin.root')}</option>{religionNodes.map(node=><option key={node.id} value={node.id}>{node.path}</option>)}</select></label><label>{t('admin.country_codes')}<input name="country_codes" placeholder="PK, AE"/></label><label>{t('admin.sort_order')}<input name="sort_order" type="number" min="0" defaultValue="0"/></label><button>{t('admin.create_option')}</button></form></div></section>}
            {actor.role==='super_admin' && <section className="panel" id="broadcasts"><h2>{t('admin.broadcast_analytics')}</h2><div className="admin-grid"><div>{broadcasts.map(item=><div className="row" key={item.id}><div><b>{item.title}</b><p>{valueLabel(item.status)} · {t('admin.target')} {item.estimated_recipients} · {t('admin.delivered')} {item.delivered_count} · {t('admin.read')} {item.read_count}</p></div>{item.status==='draft'&&<button onClick={()=>sendBroadcast(item)}>{t('admin.review_send')}</button>}</div>)}</div><form className="detail admin-form" onSubmit={createBroadcast}><h3>{t('admin.create_draft')}</h3><label>{t('admin.title')}<input name="title" required maxLength={120}/></label><label>{t('admin.message')}<textarea name="body" required maxLength={1000}/></label><label>{t('admin.category')}<select name="category"><option value="safety">{t('admin.safety_update')}</option><option value="marketing">{t('admin.marketing')}</option></select></label><label>{t('admin.audience')}<select name="audience_type"><option value="all_active">{t('admin.all_active_users')}</option><option value="country">{t('admin.country')}</option><option value="locale">{t('admin.locale')}</option></select></label><label>{t('admin.country_or_locale')}<input name="audience_value" placeholder="PK or ur"/></label><button>{t('admin.save_draft')}</button></form></div></section>}
            <section className="panel" id="reports"><h2>{t('admin.pending_reports')}</h2>{reports.length ? reports.map(report => <div className="row" key={report.id}><div><b>{valueLabel(report.category)}</b><p>{report.details || t('admin.no_details')}</p></div><div><button onClick={() => moderate('/reports/'+report.id,'resolved')}>{t('admin.resolve')}</button> <button className="warning" onClick={() => moderate('/reports/'+report.id,'dismissed')}>{t('admin.dismiss')}</button></div></div>) : <p className="empty">{t('admin.queue_clear')}</p>}</section>
            <section className="panel" id="verification"><h2>{t('admin.verification_queue')}</h2>{cases.length ? cases.map(item => <div className="row" key={item.id}><div><b>{valueLabel(item.type)}</b><p>{valueLabel(item.status)}</p></div><div><button onClick={() => moderate('/verifications/'+item.id,'approved')}>{t('admin.approve')}</button> <button className="warning" onClick={() => moderate('/verifications/'+item.id,'appeal_available')}>{t('admin.correction')}</button></div></div>) : <p className="empty">{t('admin.queue_clear')}</p>}</section>
            <section className="panel" id="audit"><h2>{t('admin.immutable_audit')}</h2>{audits.length ? audits.map(log=><div className="row audit" key={log.id}><div><b>{valueLabel(log.action.replaceAll('.','_'))}</b><p>{valueLabel(log.subject_type)} · {log.reason || t('admin.no_reason')}</p></div><div><small>{log.admin.email}</small><time>{new Date(log.created_at).toLocaleString(locale)}</time></div></div>) : <p className="empty">{t('admin.no_audits')}</p>}</section>
        </main></div>;
}
createRoot(document.getElementById('admin-root')!).render(<React.StrictMode><App /></React.StrictMode>);
