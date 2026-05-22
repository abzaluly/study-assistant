import { useState, useEffect } from 'react'
import { useNavigate } from 'react-router-dom'
import { subjectsAPI } from '../api'

const COLORS = [
  'linear-gradient(135deg,#7c3aed,#4f46e5)',
  'linear-gradient(135deg,#0ea5e9,#6366f1)',
  'linear-gradient(135deg,#ec4899,#8b5cf6)',
  'linear-gradient(135deg,#10b981,#0ea5e9)',
  'linear-gradient(135deg,#f59e0b,#ef4444)',
  'linear-gradient(135deg,#8b5cf6,#ec4899)',
]
const EMOJIS = ['📖','🔬','📐','💻','🎨','🌍','⚗️','📊']

const STAGGER = ['s1','s2','s3','s4','s5','s6','s7','s8']

export default function Dashboard() {
  const [subjects, setSubjects] = useState([])
  const [title, setTitle]       = useState('')
  const [desc,  setDesc]        = useState('')
  const [loading, setLoading]   = useState(false)
  const navigate = useNavigate()
  const user = JSON.parse(localStorage.getItem('user') || '{}')

  useEffect(() => { loadSubjects() }, [])

  const loadSubjects = async () => {
    try {
      const res = await subjectsAPI.getAll(user.id)
      setSubjects(res.data)
    } catch {}
  }

  const createSubject = async () => {
    if (!title.trim()) return
    setLoading(true)
    await subjectsAPI.create({ title, description: desc, user_id: user.id })
    setTitle(''); setDesc('')
    await loadSubjects()
    setLoading(false)
  }

  const deleteSubject = async (id, e) => {
    e.stopPropagation()
    await subjectsAPI.delete(id)
    loadSubjects()
  }

  const logout = () => { localStorage.clear(); navigate('/login') }

  return (
    <div className="page">
      <div className="orb orb-1" />

      {/* Header */}
      <div className="header">
        <div className="header-row">
          <div className="animate-in s1">
            <p style={{ color: 'rgba(255,255,255,.5)', fontSize: 14, marginBottom: 4 }}>Привет 👋</p>
            <h1 style={{ fontSize: 24, fontWeight: 800 }}>{user.name || 'Студент'}</h1>
          </div>
          <button className="btn-ghost animate-in s1" onClick={logout}>Выйти</button>
        </div>

        {/* Stats card */}
        <div
          className="animate-in s2"
          style={{
            background: 'linear-gradient(135deg,rgba(124,58,237,.30),rgba(79,70,229,.30))',
            borderRadius: 20, padding: '20px 24px',
            border: '1px solid rgba(255,255,255,.10)', marginBottom: 28,
            backdropFilter: 'blur(20px)',
          }}
        >
          <p style={{ color: 'rgba(255,255,255,.6)', fontSize: 13, marginBottom: 4 }}>Всего предметов</p>
          <p style={{ fontSize: 38, fontWeight: 800, lineHeight: 1, marginBottom: 4 }}>{subjects.length}</p>
          <p style={{ color: 'rgba(255,255,255,.45)', fontSize: 13 }}>
            {subjects.length === 0 ? 'Добавь первый предмет!' : 'Продолжай учиться 🚀'}
          </p>
        </div>

        {/* Create form */}
        <div className="card animate-in s3" style={{ marginBottom: 28 }}>
          <p style={{ fontSize: 15, fontWeight: 700, marginBottom: 14 }}>➕ Новый предмет</p>
          <input
            className="input-plain"
            style={{ marginBottom: 10 }}
            placeholder="Название предмета"
            value={title}
            onChange={e => setTitle(e.target.value)}
            onKeyDown={e => e.key === 'Enter' && createSubject()}
          />
          <input
            className="input-plain"
            style={{ marginBottom: 14 }}
            placeholder="Описание (необязательно)"
            value={desc}
            onChange={e => setDesc(e.target.value)}
          />
          <button
            className="btn btn-primary"
            onClick={createSubject}
            disabled={loading || !title.trim()}
          >
            {loading ? <><span className="spinner" /> Добавляем...</> : '+ Добавить предмет'}
          </button>
        </div>

        <p className="section-label">Мои предметы</p>
      </div>

      {/* Subject list */}
      <div className="page-content" style={{ paddingTop: 0 }}>
        {subjects.length === 0 ? (
          <div className="empty-state">
            <span className="empty-state-icon">📚</span>
            <p style={{ color: 'rgba(255,255,255,.5)', fontSize: 16, marginBottom: 6 }}>Пока нет предметов</p>
            <p style={{ color: 'rgba(255,255,255,.3)', fontSize: 14 }}>Добавь первый предмет выше ☝️</p>
          </div>
        ) : (
          <div style={{ display: 'flex', flexDirection: 'column', gap: 12 }}>
            {subjects.map((s, i) => (
              <div
                key={s.id}
                className={`card card-press animate-in ${STAGGER[i % 8]}`}
                onClick={() => navigate(`/subjects/${s.id}`)}
                style={{ position: 'relative', overflow: 'hidden', padding: 20 }}
              >
                {/* color stripe */}
                <div style={{
                  position: 'absolute', top: 0, left: 0, right: 0, height: 4,
                  background: COLORS[i % COLORS.length],
                }} />
                <div style={{ display: 'flex', alignItems: 'center', gap: 16 }}>
                  <div style={{
                    width: 52, height: 52, borderRadius: 16, flexShrink: 0,
                    background: COLORS[i % COLORS.length],
                    display: 'flex', alignItems: 'center', justifyContent: 'center',
                    fontSize: 24, boxShadow: '0 8px 20px rgba(0,0,0,.3)',
                  }}>
                    {EMOJIS[i % EMOJIS.length]}
                  </div>
                  <div style={{ flex: 1, minWidth: 0 }}>
                    <p style={{
                      fontWeight: 700, fontSize: 16, marginBottom: 4,
                      overflow: 'hidden', textOverflow: 'ellipsis', whiteSpace: 'nowrap',
                    }}>{s.title}</p>
                    <p style={{
                      color: 'rgba(255,255,255,.42)', fontSize: 13,
                      overflow: 'hidden', textOverflow: 'ellipsis', whiteSpace: 'nowrap',
                    }}>{s.description || 'Нет описания'}</p>
                  </div>
                  <div style={{ display: 'flex', alignItems: 'center', gap: 8 }}>
                    <button
                      onClick={e => deleteSubject(s.id, e)}
                      style={{
                        background: 'rgba(239,68,68,.14)', border: '1px solid rgba(239,68,68,.22)',
                        color: '#fca5a5', width: 36, height: 36, borderRadius: 10,
                        cursor: 'pointer', fontSize: 16, display: 'flex',
                        alignItems: 'center', justifyContent: 'center',
                        transition: 'background 180ms ease, transform 130ms var(--ease-out)',
                      }}
                    >✕</button>
                    <span style={{ color: 'rgba(255,255,255,.3)', fontSize: 22 }}>›</span>
                  </div>
                </div>
              </div>
            ))}
          </div>
        )}
      </div>
    </div>
  )
}
