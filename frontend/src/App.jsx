import { Routes, Route, Navigate } from 'react-router-dom'
import Login from './pages/Login'
import Register from './pages/Register'
import Dashboard from './pages/Dashboard'
import SubjectDetail from './pages/SubjectDetail'
import LectureDetail from './pages/LectureDetail'

function PrivateRoute({ children }) {
  const token = localStorage.getItem('token')
  return token ? children : <Navigate to="/login" />
}

export default function App() {
  return (
    <Routes>
      <Route path="/login" element={<Login />} />
      <Route path="/register" element={<Register />} />
      <Route path="/" element={<PrivateRoute><Dashboard /></PrivateRoute>} />
      <Route path="/subjects/:id" element={<PrivateRoute><SubjectDetail /></PrivateRoute>} />
      <Route path="/lectures/:id" element={<PrivateRoute><LectureDetail /></PrivateRoute>} />
    </Routes>
  )
}