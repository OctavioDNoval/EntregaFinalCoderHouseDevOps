package com.entregafinal.demo.service;

import com.entregafinal.demo.model.Tarea;
import com.entregafinal.demo.repository.TareaRepository;
import org.springframework.stereotype.Service;

import java.util.List;

@Service
public class TareaService {

    private final TareaRepository repository;

    public TareaService(TareaRepository repository) {
        this.repository = repository;
    }

    public List<Tarea> listar() {
        return repository.findAll();
    }

    public Tarea obtener(Long id) {
        return repository.findById(id)
                .orElseThrow(() -> new RuntimeException("Tarea no encontrada: " + id));
    }

    public Tarea crear(Tarea tarea) {
        return repository.save(tarea);
    }

    public Tarea actualizar(Long id, Tarea tarea) {
        Tarea existente = obtener(id);
        existente.setNombre(tarea.getNombre());
        existente.setDescripcion(tarea.getDescripcion());
        existente.setCompletada(tarea.isCompletada());
        return repository.save(existente);
    }

    public void eliminar(Long id) {
        repository.deleteById(id);
    }
}
