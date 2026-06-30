package com.entregafinal.demo.repository;

import com.entregafinal.demo.model.Tarea;
import org.springframework.data.jpa.repository.JpaRepository;

public interface TareaRepository extends JpaRepository<Tarea, Long> {
}
