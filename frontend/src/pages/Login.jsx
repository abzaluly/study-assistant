import { useState } from 'react'
import { useNavigate, Link } from 'react-router-dom'
import { authAPI } from '../api'

const features = [
  { icon: '🤖', text: 'AI анализ конспектов' },
  { icon: '📝', text: 'Генерация тестов' },
  { icon: '📊', text: 'Отслеживание прогресса' },
  { icon: '💡', text: 'Персонализированные объяснения' },
]

export default function Login() {
  const [email, setEmail]       = useState('')
  const [password, setPassword] = useState('')
  const [error, setError]       = useState('')
  const [loading, setLoading]   = useState(false)
  const navigate = useNavigate()

  const handleSubmit = async (e) => {
    e.preventDefault()
    setLoading(true)
    setError('')
    try {
      const res = await authAPI.login({ email, password })
      localStorage.setItem('token', res.data.token)
      localStorage.setItem('user', JSON.stringify(res.data.user))
      navigate('/')
    } catch (err) {
      if (!err?.response) {
        setError('Сервер недоступен. Убедись что backend запущен.')
      } else {
        setError('Неверный email или пароль')
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
          AI-платформа для студентов Казахстана
        </p>

        <div style={{ display: 'flex', flexDirection: 'column', gap: 10, maxWidth: 420 }}>
          {features.map((f, i) => (
            <div
              key={i}
              className={`card animate-in s${i + 4}`}
              style={{ display: 'flex', alignItems: 'center', gap: 16, padding: '14px 18px' }}
            >
              <span style={{ fontSize: 22 }}>{f.icon}</span>
              <span style={{ color: 'rgba(255,255,255,.85)', fontSize: 15, fontWeight: 500 }}>{f.text}</span>
            </div>
          ))}
        </div>
      </div>

      {/* Right panel */}
      <div className="auth-right">
        <div className="auth-form-card">
          <h2 style={{ fontSize: 24, fontWeight: 700, marginBottom: 4 }}>Добро пожаловать!</h2>
          <p style={{ color: 'rgba(255,255,255,.4)', fontSize: 14, marginBottom: 24 }}>
            Войди в свой аккаунт
          </p>

          {error && <div className="error-banner">{error}</div>}

          <form onSubmit={handleSubmit} style={{ display: 'flex', flexDirection: 'column', gap: 16 }}>
            <div>
              <label className="label">Email</label>
              <div className="input-group">
                <span className="input-group-icon">✉️</span>
                <input
                  className="input-field"
                  type="email"
                  placeholder="example@email.com"
                  value={email}
                  onChange={e => setEmail(e.target.value)}
                  required
                />
              </div>
            </div>

            <div>
              <label className="label">Пароль</label>
              <div className="input-group">
                <span className="input-group-icon">🔐</span>
                <input
                  className="input-field"
                  type="password"
                  placeholder="Введи пароль"
                  value={password}
                  onChange={e => setPassword(e.target.value)}
                  required
                />
              </div>
            </div>

            <button
              className="btn btn-primary"
              type="submit"
              disabled={loading}
              style={{ marginTop: 8 }}
            >
              {loading ? <><span className="spinner" /> Входим...</> : 'Войти →'}
            </button>
          </form>

          <div style={{ display: 'flex', alignItems: 'center', gap: 12, margin: '20px 0' }}>
            <div style={{ flex: 1, height: 1, background: 'rgba(255,255,255,.10)' }} />
            <span style={{ color: 'rgba(255,255,255,.3)', fontSize: 13 }}>или</span>
            <div style={{ flex: 1, height: 1, background: 'rgba(255,255,255,.10)' }} />
          </div>

          <p style={{ textAlign: 'center', color: 'rgba(255,255,255,.45)', fontSize: 15 }}>
            Нет аккаунта?{' '}
            <Link to="/register" style={{ color: '#a78bfa', textDecoration: 'none', fontWeight: 700 }}>
              Создать аккаунт
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
