import { useEffect, useState } from 'react'
import './App.css'

interface Tarea {
  id: number
  nombre: string
  descripcion: string
  completada: boolean
}

const API = 'http://localhost:8080/api/tareas'

function App() {
  const [tareas, setTareas] = useState<Tarea[]>([])
  const [nombre, setNombre] = useState('')
  const [descripcion, setDescripcion] = useState('')

  useEffect(() => {
    fetch(API)
      .then(res => res.json())
      .then(setTareas)
  }, [])

  function agregar(e: React.FormEvent) {
    e.preventDefault()
    if (!nombre.trim()) return
    fetch(API, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ nombre, descripcion, completada: false })
    })
      .then(res => res.json())
      .then(nueva => {
        setTareas(prev => [...prev, nueva])
        setNombre('')
        setDescripcion('')
      })
  }

  function toggle(tarea: Tarea) {
    fetch(`${API}/${tarea.id}`, {
      method: 'PUT',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ ...tarea, completada: !tarea.completada })
    })
      .then(res => res.json())
      .then(actualizada => {
        setTareas(prev => prev.map(t => t.id === actualizada.id ? actualizada : t))
      })
  }

  function eliminar(id: number) {
    fetch(`${API}/${id}`, { method: 'DELETE' })
      .then(() => setTareas(prev => prev.filter(t => t.id !== id)))
  }

  return (
    <div className="container">
      <h1>TO-DO App</h1>

      <form onSubmit={agregar} className="form">
        <input
          placeholder="Nombre de la tarea"
          value={nombre}
          onChange={e => setNombre(e.target.value)}
          required
        />
        <input
          placeholder="Descripción"
          value={descripcion}
          onChange={e => setDescripcion(e.target.value)}
        />
        <button type="submit">Agregar</button>
      </form>

      <ul className="lista">
        {tareas.map(t => (
          <li key={t.id} className={t.completada ? 'hecho' : ''}>
            <div className="info">
              <strong>{t.nombre}</strong>
              <span>{t.descripcion}</span>
            </div>
            <div className="acciones">
              <button onClick={() => toggle(t)}>
                {t.completada ? 'Desmarcar' : 'Completar'}
              </button>
              <button className="eliminar" onClick={() => eliminar(t.id)}>
                Eliminar
              </button>
            </div>
          </li>
        ))}
        {tareas.length === 0 && <p className="vacio">No hay tareas aún</p>}
      </ul>
    </div>
  )
}

export default App
