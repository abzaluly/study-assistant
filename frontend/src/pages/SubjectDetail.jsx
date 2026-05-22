import { useState, useEffect } from 'react'
import { useParams, useNavigate } from 'react-router-dom'
import { lecturesAPI, subjectsAPI } from '../api'

const STAGGER = ['s1','s2','s3','s4','s5','s6','s7','s8']

export default function SubjectDetail() {
  const { id } = useParams()
  const [lectures, setLectures] = useState([])
  const [title, setTitle]       = useState('')
  const [loading, setLoading]   = useState(false)
  const navigate = useNavigate()

  useEffect(() => { loadData() }, [])

  const loadData = async () => {
    try {
      const res = await lecturesAPI.getAll(id)
      setLectures(res.data)
    } catch {}
  }

  const createLecture = async () => {
    if (!title.trim()) return
    setLoading(true)
    await lecturesAPI.create({ subject_id: id, title, order_index: lectures.length })
    setTitle('')
    await loadData()
    setLoading(false)
  }

  const deleteLecture = async (lectureId, e) => {
    e.stopPropagation()
    await lecturesAPI.delete(lectureId)
    loadData()
  }

  const plural = (n) => n === 1 ? 'лекция' : n < 5 ? 'лекции' : 'лекций'

  return (
    <div className="page">
      <div className="orb orb-1" />

      <div className="header">
        <button className="btn-ghost animate-in s1" onClick={() => navigate('/')} style={{ marginBottom: 20 }}>
          ← Назад
        </button>

        <h1 className="animate-in s2" style={{ fontSize: 26, fontWeight: 800, marginBottom: 4 }}>
          📖 Лекции
        </h1>
        <p className="animate-in s2" style={{ color: 'rgba(255,255,255,.4)', fontSize: 14, marginBottom: 24 }}>
          {lectures.length} {plural(lectures.length)}
        </p>

        {/* Add lecture */}
        <div className="card animate-in s3" style={{ marginBottom: 28 }}>
          <p className="section-label" style={{ marginBottom: 12 }}>Новая лекция</p>
          <div style={{ display: 'flex', gap: 10 }}>
            <input
              className="input-plain"
              style={{ flex: 1 }}
              placeholder="Название лекции"
              value={title}
              onChange={e => setTitle(e.target.value)}
              onKeyDown={e => e.key === 'Enter' && createLecture()}
            />
            <button
              className="btn btn-primary"
              style={{ width: 'auto', padding: '13px 20px', whiteSpace: 'nowrap' }}
              onClick={createLecture}
              disabled={loading || !title.trim()}
            >
              {loading ? <span className="spinner" /> : '+ Добавить'}
            </button>
          </div>
        </div>
      </div>

      <div className="page-content" style={{ paddingTop: 0 }}>
        {lectures.length === 0 ? (
          <div className="empty-state">
            <span style={{ fontSize: 48, marginBottom: 16, display: 'block' }}>📝</span>
            <p style={{ color: 'rgba(255,255,255,.5)', fontSize: 16, marginBottom: 6 }}>Пока нет лекций</p>
            <p style={{ color: 'rgba(255,255,255,.3)', fontSize: 14 }}>Добавь первую лекцию выше ☝️</p>
          </div>
        ) : (
          <div style={{ display: 'flex', flexDirection: 'column', gap: 10 }}>
            {lectures.map((l, i) => (
              <div
                key={l.id}
                className={`card card-press animate-in ${STAGGER[i % 8]}`}
                onClick={() => navigate(`/lectures/${l.id}`)}
                style={{ padding: '18px 20px', display: 'flex', alignItems: 'center', gap: 16 }}
              >
                <div className="num-pill">{i + 1}</div>
                <div style={{ flex: 1, minWidth: 0 }}>
                  <p style={{
                    fontWeight: 600, fontSize: 15,
                    overflow: 'hidden', textOverflow: 'ellipsis', whiteSpace: 'nowrap',
                  }}>{l.title}</p>
                  <p style={{ color: 'rgba(255,255,255,.38)', fontSize: 12, marginTop: 2 }}>
                    Нажми чтобы открыть
                  </p>
                </div>
                <div style={{ display: 'flex', alignItems: 'center', gap: 8 }}>
                  <button
                    onClick={e => deleteLecture(l.id, e)}
                    style={{
                      background: 'rgba(239,68,68,.14)', border: '1px solid rgba(239,68,68,.22)',
                      color: '#fca5a5', width: 34, height: 34, borderRadius: 10,
                      cursor: 'pointer', fontSize: 14, display: 'flex',
                      alignItems: 'center', justifyContent: 'center',
                      transition: 'background 180ms ease, transform 130ms var(--ease-out)',
                    }}
                  >✕</button>
                  <span style={{ color: 'rgba(255,255,255,.28)', fontSize: 22 }}>›</span>
                </div>
              </div>
            ))}
          </div>
        )}
      </div>
    </div>
  )
}
