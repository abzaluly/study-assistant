import { useState } from 'react'
import { useNavigate, Link } from 'react-router-dom'
import { authAPI } from '../api'

const LEVELS = [
  { key: 'beginner',     icon: '🌱', label: 'Начинающий',    desc: 'Только начинаю разбираться' },
  { key: 'intermediate', icon: '📚', label: 'Средний',        desc: 'Знаю основы, хочу глубже' },
  { key: 'advanced',     icon: '🚀', label: 'Продвинутый',    desc: 'Уверенно знаю предмет' },
]

const stats = [
  { num: 'AI',  label: 'Анализ конспектов' },
  { num: '∞',   label: 'Тестов и заданий' },
  { num: '24/7', label: 'Доступно всегда' },
]

export default function Register() {
  const [form, setForm]   = useState({ name: '', email: '', password: '', age: '', interests: '' })
  const [level, setLevel] = useState('beginner')
  const [error, setError] = useState('')
  const [loading, setLoading] = useState(false)
  const navigate = useNavigate()

  const handleSubmit = async (e) => {
    e.preventDefault()
    setLoading(true)
    setError('')
    try {
      const res = await authAPI.register({
        ...form,
        age:           form.age ? parseInt(form.age) : null,
        interests:     form.interests ? form.interests.split(',').map(i => i.trim()).filter(Boolean) : [],
        student_level: level,
      })
      localStorage.setItem('token', res.data.token)
      localStorage.setItem('user',  JSON.stringify(res.data.user))
      navigate('/')
    } catch (err) {
      const msg = err?.response?.data?.detail
      if (msg === 'Email already registered') {
        setError('Этот email уже зарегистрирован. Попробуй войти.')
      } else if (msg) {
        setError(msg)
      } else if (!err?.response) {
        setError('Сервер недоступен. Убедись что backend запущен.')
      } else {
        setError('Ошибка регистрации. Попробуй снова.')
      }
    }
    setLoading(false)
  }

  return (
    <div className="auth-page">
      <div className="orb orb-1" />
      <div className="orb orb-2" />

      {/* Left panel */}
      <div className="auth-left">
        <span className="animate-in s1" style={{ fontSize: 72, marginBottom: 20, display: 'block' }}>📚</span>
        <h1 className="grad animate-in s2" style={{ fontSize: 48, fontWeight: 800, marginBottom: 12, letterSpacing: -1 }}>
          Sabaq Coach
        </h1>
        <p className="animate-in s3" style={{ color: 'rgba(255,255,255,.5)', fontSize: 20, marginBottom: 48 }}>
          Начни учиться умнее уже сегодня
        </p>

        <div className="card animate-in s4" style={{ marginBottom: 28, maxWidth: 420 }}>
          <p style={{ fontWeight: 700, fontSize: 15, marginBottom: 10 }}>Почему Sabaq Coach?</p>
          <p style={{ color: 'rgba(255,255,255,.6)', fontSize: 14, lineHeight: 1.65 }}>
            Наш AI анализирует твои конспекты, находит пробелы в знаниях
            и генерирует персонализированные тесты — всё в одном приложении.
          </p>
        </div>

        <div className="animate-in s5" style={{ display: 'flex', gap: 14, maxWidth: 420 }}>
          {stats.map((s, i) => (
            <div key={i} className="card" style={{ flex: 1, textAlign: 'center', padding: '14px 8px' }}>
              <span className="grad" style={{ display: 'block', fontSize: 22, fontWeight: 800, marginBottom: 4 }}>{s.num}</span>
              <span style={{ fontSize: 11, color: 'rgba(255,255,255,.45)' }}>{s.label}</span>
            </div>
          ))}
        </div>
      </div>

      {/* Right panel */}
      <div className="auth-right" style={{ padding: '40px 48px' }}>
        <div className="auth-form-card" style={{ padding: '32px 28px' }}>
          <h2 style={{ fontSize: 22, fontWeight: 700, marginBottom: 4 }}>Создать аккаунт</h2>
          <p style={{ color: 'rgba(255,255,255,.4)', fontSize: 14, marginBottom: 24 }}>
            Заполни форму чтобы начать
          </p>

          {error && <div className="error-banner">{error}</div>}

          <form onSubmit={handleSubmit} style={{ display: 'flex', flexDirection: 'column', gap: 14 }}>
            {/* Name */}
            <div>
              <label className="label">Имя</label>
              <div className="input-group">
                <span className="input-group-icon">👤</span>
                <input className="input-field" type="text" placeholder="Как тебя зовут?"
                  value={form.name} onChange={e => setForm({ ...form, name: e.target.value })} />
              </div>
            </div>

            {/* Email */}
            <div>
              <label className="label">Email</label>
              <div className="input-group">
                <span className="input-group-icon">✉️</span>
                <input className="input-field" type="email" placeholder="example@email.com"
                  value={form.email} onChange={e => setForm({ ...form, email: e.target.value })} />
              </div>
            </div>

            {/* Password */}
            <div>
              <label className="label">Пароль</label>
              <div className="input-group">
                <span className="input-group-icon">🔐</span>
                <input className="input-field" type="password" placeholder="Придумай пароль"
                  value={form.password} onChange={e => setForm({ ...form, password: e.target.value })} />
              </div>
            </div>

            {/* Age */}
            <div>
              <label className="label">Возраст</label>
              <div className="input-group">
                <span className="input-group-icon">🎂</span>
                <input className="input-field" type="number" placeholder="Сколько тебе лет?"
                  value={form.age} onChange={e => setForm({ ...form, age: e.target.value })} />
              </div>
            </div>

            {/* Interests */}
            <div>
              <label className="label">Интересы</label>
              <div className="input-group">
                <span className="input-group-icon">⭐</span>
                <input className="input-field" type="text" placeholder="футбол, аниме, музыка..."
                  value={form.interests} onChange={e => setForm({ ...form, interests: e.target.value })} />
              </div>
              <p style={{ color: 'rgba(255,255,255,.3)', fontSize: 11, marginTop: 4 }}>
                Через запятую — AI будет объяснять темы через твои интересы
              </p>
            </div>

            {/* Student level */}
            <div>
              <label className="label">Уровень знаний</label>
              <div style={{ display: 'flex', gap: 8, marginTop: 4 }}>
                {LEVELS.map(l => (
                  <button
                    key={l.key}
                    type="button"
                    onClick={() => setLevel(l.key)}
                    style={{
                      flex: 1, padding: '10px 6px', borderRadius: 12, border: 'none', cursor: 'pointer',
                      background: level === l.key
                        ? 'linear-gradient(135deg,rgba(124,58,237,.5),rgba(79,70,229,.4))'
                        : 'rgba(255,255,255,.04)',
                      outline: level === l.key ? '1.5px solid rgba(124,58,237,.7)' : '1px solid rgba(255,255,255,.08)',
                      transition: 'all 150ms ease',
                      textAlign: 'center',
                    }}
                  >
                    <div style={{ fontSize: 22, marginBottom: 4 }}>{l.icon}</div>
                    <div style={{ color: level === l.key ? 'white' : 'rgba(255,255,255,.5)', fontSize: 12, fontWeight: 700 }}>{l.label}</div>
                    <div style={{ color: 'rgba(255,255,255,.3)', fontSize: 10, marginTop: 2, lineHeight: 1.3 }}>{l.desc}</div>
                  </button>
                ))}
              </div>
            </div>

            <button className="btn btn-primary" type="submit" disabled={loading} style={{ marginTop: 8 }}>
              {loading ? <><span className="spinner" /> Создаём...</> : 'Создать аккаунт →'}
            </button>
          </form>

          <p style={{ textAlign: 'center', marginTop: 16, color: 'rgba(255,255,255,.4)', fontSize: 14 }}>
            Уже есть аккаунт?{' '}
            <Link to="/login" style={{ color: '#a78bfa', textDecoration: 'none', fontWeight: 700 }}>
              Войти
            </Link>
          </p>
        </div>

        <p style={{ color: 'rgba(255,255,255,.22)', fontSize: 13 }}>
          🎓 Разработано для студентов Казахстана
        </p>
      </div>
    </div>
  )
}
