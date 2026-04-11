-- Pega aqui el script de la Base de datos
-- =====================================================
-- Plataforma Duna - Esquema de Base de Datos PostgreSQL
-- Versión: 5.0 (FINAL CON CALIFICACIONES)
-- Fecha: 2026-03-31
-- Timezone: UTC-5 (America/Bogota)
-- Arquitectura: Separación por dominio
-- Autenticación: Email como identificador (no único global)
-- Calificaciones: Entidad separada (relación 1:1 con Encargo)
-- Wilson Score: Calculado asíncronamente en Search Module
-- =====================================================

-- =====================================================
-- EXTENSIONES
-- =====================================================
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "btree_gist";

-- =====================================================
-- 1. AUTENTICACIÓN (Solo gestión de contraseña - SIN email)
-- =====================================================

CREATE TABLE credencial (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    password_hash VARCHAR(255) NOT NULL,
    password_salt VARCHAR(255),
    intentos_fallidos INTEGER NOT NULL DEFAULT 0,
    bloqueo_hasta TIMESTAMP,
    ultimo_login TIMESTAMP,
    estado BOOLEAN NOT NULL DEFAULT TRUE,
    fecha_creacion TIMESTAMP NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_credencial_estado ON credencial(estado);

-- =====================================================
-- 2. CLIENTE (Dominio independiente + email no único global)
-- =====================================================

CREATE TABLE cliente (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    credencial_id UUID NOT NULL REFERENCES credencial(id) ON DELETE RESTRICT,
    email VARCHAR(255) NOT NULL,
    tipo_documento VARCHAR(20) NOT NULL,
    numero_documento VARCHAR(20) NOT NULL,
    nombre VARCHAR(255) NOT NULL,
    telefono VARCHAR(20),
    estado VARCHAR(20) NOT NULL DEFAULT 'ACTIVO' CHECK (estado IN ('ACTIVO', 'INACTIVO')),
    direccion_principal VARCHAR(255),
    ciudad VARCHAR(100),
    fecha_nacimiento DATE,
    fecha_creacion TIMESTAMP NOT NULL DEFAULT NOW(),
    fecha_actualizacion TIMESTAMP,
    CONSTRAINT uk_cliente_credencial UNIQUE (credencial_id)
);

CREATE INDEX idx_cliente_estado ON cliente(estado);
CREATE INDEX idx_cliente_email ON cliente(email);

-- =====================================================
-- 3. PROVEEDOR (Dominio independiente + email no único global)
-- =====================================================

CREATE TABLE proveedor (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    credencial_id UUID NOT NULL REFERENCES credencial(id) ON DELETE RESTRICT,
    email VARCHAR(255) NOT NULL,
    tipo_documento VARCHAR(20) NOT NULL,
    numero_documento VARCHAR(20) NOT NULL,
    nombre VARCHAR(255) NOT NULL,
    telefono VARCHAR(20),
    estado VARCHAR(20) NOT NULL DEFAULT 'ACTIVO' CHECK (estado IN ('ACTIVO', 'INACTIVO')),
    trust_badge_verified BOOLEAN NOT NULL DEFAULT FALSE,
    precio_hora_ref DECIMAL(10,2),
    biografia VARCHAR(1000),
    foto_perfil_url VARCHAR(500),
    fecha_creacion TIMESTAMP NOT NULL DEFAULT NOW(),
    fecha_actualizacion TIMESTAMP,
    CONSTRAINT uk_proveedor_credencial UNIQUE (credencial_id)
);

CREATE INDEX idx_proveedor_estado ON proveedor(estado);
CREATE INDEX idx_proveedor_trust_badge ON proveedor(trust_badge_verified);
CREATE INDEX idx_proveedor_email ON proveedor(email);

-- =====================================================
-- 4. ADMINISTRADOR (Dominio independiente + email no único global)
-- =====================================================

CREATE TABLE administrador (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    credencial_id UUID NOT NULL REFERENCES credencial(id) ON DELETE RESTRICT,
    email VARCHAR(255) NOT NULL,
    tipo_documento VARCHAR(20) NOT NULL,
    numero_documento VARCHAR(20) NOT NULL,
    nombre VARCHAR(255) NOT NULL,
    telefono VARCHAR(20),
    estado VARCHAR(20) NOT NULL DEFAULT 'ACTIVO' CHECK (estado IN ('ACTIVO', 'INACTIVO')),
    fecha_creacion TIMESTAMP NOT NULL DEFAULT NOW(),
    fecha_actualizacion TIMESTAMP,
    CONSTRAINT uk_administrador_credencial UNIQUE (credencial_id)
);

CREATE INDEX idx_administrador_estado ON administrador(estado);
CREATE INDEX idx_administrador_email ON administrador(email);

-- =====================================================
-- 5. TRUST BADGE AUDIT
-- =====================================================

CREATE TABLE trust_badge_audit (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    proveedor_id UUID NOT NULL REFERENCES proveedor(id) ON DELETE CASCADE,
    estado_anterior BOOLEAN,
    estado_nuevo BOOLEAN NOT NULL,
    motivo VARCHAR(500),
    cambiado_por UUID NOT NULL REFERENCES administrador(id) ON DELETE RESTRICT,
    fecha_cambio TIMESTAMP NOT NULL DEFAULT NOW()
);

-- =====================================================
-- 6. SERVICIO (CATÁLOGO)
-- =====================================================

CREATE TABLE servicio (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    nombre VARCHAR(255) NOT NULL,
    descripcion VARCHAR(500),
    categoria VARCHAR(100),
    estado VARCHAR(20) NOT NULL DEFAULT 'ACTIVO' CHECK (estado IN ('ACTIVO', 'INACTIVO')),
    fecha_creacion TIMESTAMP NOT NULL DEFAULT NOW(),
    fecha_actualizacion TIMESTAMP,
    CONSTRAINT uk_servicio_nombre UNIQUE (nombre)
);

CREATE INDEX idx_servicio_categoria ON servicio(categoria);
CREATE INDEX idx_servicio_estado ON servicio(estado);

-- =====================================================
-- 7. SERVICIO PROVEEDOR
-- =====================================================

CREATE TABLE servicio_proveedor (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    proveedor_id UUID NOT NULL REFERENCES proveedor(id) ON DELETE CASCADE,
    servicio_id UUID NOT NULL REFERENCES servicio(id) ON DELETE RESTRICT,
    estado VARCHAR(20) NOT NULL DEFAULT 'ACTIVO' CHECK (estado IN ('ACTIVO', 'PAUSADO', 'CANCELADO')),
    precio_referencial DECIMAL(10,2),
    alcance VARCHAR(500),
    cobertura VARCHAR(255),
    tiempos VARCHAR(255),
    condiciones VARCHAR(1000),
    fecha_creacion TIMESTAMP NOT NULL DEFAULT NOW(),
    fecha_actualizacion TIMESTAMP,
    CONSTRAINT uk_servicio_proveedor UNIQUE (proveedor_id, servicio_id)
);

CREATE INDEX idx_servicio_proveedor_estado ON servicio_proveedor(estado);

-- =====================================================
-- 7.1 PROVEEDOR MÉTRICAS (Wilson Score persistence)
-- =====================================================

CREATE TABLE proveedor_metricas (
    proveedor_id UUID PRIMARY KEY REFERENCES proveedor(id) ON DELETE CASCADE,
    wilson_score DECIMAL(5,4),
    total_calificaciones INTEGER NOT NULL DEFAULT 0,
    suma_puntuaciones INTEGER NOT NULL DEFAULT 0,
    promedio_simple DECIMAL(3,2),
    primera_calificacion DATE,
    ultima_actualizacion TIMESTAMP
);

CREATE INDEX idx_proveedor_metricas_wilson ON proveedor_metricas(wilson_score DESC);
CREATE INDEX idx_proveedor_metricas_total ON proveedor_metricas(total_calificaciones DESC);

-- =====================================================
-- 8. DISPONIBILIDAD PROVEEDOR
-- =====================================================

CREATE TABLE disponibilidad_proveedor (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    proveedor_id UUID NOT NULL REFERENCES proveedor(id) ON DELETE CASCADE,
    fecha DATE NOT NULL,
    hora_inicio TIME NOT NULL,
    hora_fin TIME NOT NULL,
    tipo_recurrencia VARCHAR(20) CHECK (tipo_recurrencia IN ('DIARIO', 'SEMANAL', 'NINGUNA')),
    dias_semana INTEGER[],
    recurrencia_fin DATE,
    estado VARCHAR(20) NOT NULL DEFAULT 'DISPONIBLE' CHECK (estado IN ('DISPONIBLE', 'OCUPADA', 'BLOQUEADA')),
    encargo_id UUID,
    fecha_creacion TIMESTAMP NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_disponibilidad_fecha ON disponibilidad_proveedor(proveedor_id, fecha);
CREATE INDEX idx_disponibilidad_estado ON disponibilidad_proveedor(estado);

-- =====================================================
-- 9. ENCARGO (SIN calificación - está en tabla separada)
-- =====================================================

CREATE TABLE encargo (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    cliente_id UUID NOT NULL REFERENCES cliente(id) ON DELETE RESTRICT,
    proveedor_id UUID REFERENCES proveedor(id) ON DELETE SET NULL,
    servicio_id UUID NOT NULL REFERENCES servicio(id) ON DELETE RESTRICT,
    estado VARCHAR(30) NOT NULL DEFAULT 'PENDIENTE' 
        CHECK (estado IN (
            'PENDIENTE', 'AGENDADO', 'ATENDIDO', 'FINALIZADO', 
            'RECHAZADO', 'CANCELADO_PROVEEDOR', 'CANCELADO_CLIENTE', 'EXPIRADO'
        )),
    descripcion_problema TEXT,
    direccion_servicio VARCHAR(255),
    fecha_servicio TIMESTAMP NOT NULL,
    duracion_estimada INTEGER,
    precio_acordado DECIMAL(10,2),
    motivo_rechazo VARCHAR(500),
    version INTEGER NOT NULL DEFAULT 0,
    fecha_creacion TIMESTAMP NOT NULL DEFAULT NOW(),
    fecha_actualizacion TIMESTAMP
);

CREATE INDEX idx_encargo_cliente ON encargo(cliente_id);
CREATE INDEX idx_encargo_proveedor ON encargo(proveedor_id);
CREATE INDEX idx_encargo_estado ON encargo(estado);
CREATE INDEX idx_encargo_fecha ON encargo(fecha_servicio);

-- =====================================================
-- 10. CALIFICACIÓN (Entidad separada - relación 1:1 con Encargo)
-- =====================================================

CREATE TABLE calificacion (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    encargo_id UUID NOT NULL REFERENCES encargo(id) ON DELETE CASCADE,
    proveedor_id UUID NOT NULL REFERENCES proveedor(id) ON DELETE RESTRICT,
    cliente_id UUID NOT NULL REFERENCES cliente(id) ON DELETE RESTRICT,
    puntuacion INTEGER NOT NULL CHECK (puntuacion >= 1 AND puntuacion <= 5),
    comentario VARCHAR(500),
    fecha_creacion TIMESTAMP NOT NULL DEFAULT NOW(),
    CONSTRAINT uk_calificacion_encargo UNIQUE (encargo_id)
);

CREATE INDEX idx_calificacion_proveedor ON calificacion(proveedor_id);
CREATE INDEX idx_calificacion_puntuacion ON calificacion(puntuacion);
CREATE INDEX idx_calificacion_cliente ON calificacion(cliente_id);

-- =====================================================
-- 11. ENCARGO HISTORIAL
-- =====================================================

CREATE TABLE encargo_historial (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    encargo_id UUID NOT NULL REFERENCES encargo(id) ON DELETE CASCADE,
    estado_anterior VARCHAR(30),
    estado_nuevo VARCHAR(30) NOT NULL,
    usuario_id UUID NOT NULL,
    tipo_usuario VARCHAR(20) NOT NULL CHECK (tipo_usuario IN ('CLIENTE', 'PROVEEDOR', 'ADMIN')),
    comentario VARCHAR(500),
    timestamp TIMESTAMP NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_encargo_historial_encargo ON encargo_historial(encargo_id);

-- =====================================================
-- 12. NOTIFICACIÓN
-- =====================================================

CREATE TABLE notificacion (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    usuario_id UUID NOT NULL,
    tipo_usuario VARCHAR(20) NOT NULL CHECK (tipo_usuario IN ('CLIENTE', 'PROVEEDOR', 'ADMIN')),
    tipo VARCHAR(20) NOT NULL CHECK (tipo IN ('IN_APP', 'EMAIL')),
    titulo VARCHAR(255) NOT NULL,
    mensaje TEXT NOT NULL,
    estado VARCHAR(20) NOT NULL DEFAULT 'NO_LEIDA' CHECK (estado IN ('LEIDA', 'NO_LEIDA')),
    referencia_tipo VARCHAR(50),
    referencia_id UUID,
    fecha_lectura TIMESTAMP,
    fecha_creacion TIMESTAMP NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_notificacion_usuario ON notificacion(usuario_id, tipo_usuario, estado);
CREATE INDEX idx_notificacion_estado ON notificacion(estado);

-- =====================================================
-- 13. AUDIT LOG
-- =====================================================

CREATE TABLE audit_log (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    entidad VARCHAR(100) NOT NULL,
    entidad_id UUID NOT NULL,
    accion VARCHAR(50) NOT NULL CHECK (accion IN ('CREATE', 'UPDATE', 'DELETE')),
    usuario_id UUID,
    tipo_usuario VARCHAR(20) CHECK (tipo_usuario IN ('CLIENTE', 'PROVEEDOR', 'ADMIN')),
    datos_anteriores JSONB,
    datos_nuevos JSONB,
    ip_origen VARCHAR(45),
    user_agent VARCHAR(500),
    timestamp TIMESTAMP NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_audit_entidad ON audit_log(entidad, entidad_id);
CREATE INDEX idx_audit_usuario ON audit_log(usuario_id, tipo_usuario);
CREATE INDEX idx_audit_timestamp ON audit_log(timestamp);

-- =====================================================
-- 14. VISTAS AUXILIARES
-- =====================================================

-- Vista: Proveedores con trust badge y servicios activos
CREATE OR REPLACE VIEW vista_proveedores_activos AS
SELECT 
    p.id,
    p.nombre,
    p.email,
    p.telefono,
    p.trust_badge_verified,
    p.precio_hora_ref,
    p.biografia,
    p.foto_perfil_url,
    COUNT(sp.id) AS servicios_activos
FROM proveedor p
LEFT JOIN servicio_proveedor sp ON p.id = sp.proveedor_id AND sp.estado = 'ACTIVO'
WHERE p.estado = 'ACTIVO' AND p.trust_badge_verified = TRUE
GROUP BY p.id, p.nombre, p.email, p.telefono, p.trust_badge_verified, p.precio_hora_ref, p.biografia, p.foto_perfil_url;

-- Vista: Encargos pendientes con datos relacionados
CREATE OR REPLACE VIEW vista_encargos_pendientes AS
SELECT 
    e.id,
    e.descripcion_problema,
    e.fecha_servicio,
    e.direccion_servicio,
    e.estado,
    c.nombre AS cliente_nombre,
    c.email AS cliente_email,
    p.nombre AS proveedor_nombre,
    s.nombre AS servicio_nombre
FROM encargo e
INNER JOIN cliente c ON e.cliente_id = c.id
LEFT JOIN proveedor p ON e.proveedor_id = p.id
INNER JOIN servicio s ON e.servicio_id = s.id
WHERE e.estado = 'PENDIENTE';

-- Vista: Promedio de calificaciones por proveedor (para Search Module)
CREATE OR REPLACE VIEW vista_proveedores_rating AS
SELECT 
    p.id AS proveedor_id,
    p.nombre AS proveedor_nombre,
    p.trust_badge_verified,
    COUNT(c.id) AS total_calificaciones,
    AVG(c.puntuacion) AS promedio_puntuacion,
    -- Wilson Score calculado en aplicación, no en BD
    -- Este promedio es solo referencia
    MIN(c.fecha_creacion) AS primera_calificacion,
    MAX(c.fecha_creacion) AS ultima_calificacion
FROM proveedor p
LEFT JOIN calificacion c ON p.id = c.proveedor_id
WHERE p.estado = 'ACTIVO'
GROUP BY p.id, p.nombre, p.trust_badge_verified;

-- =====================================================
-- 15. FUNCIONES Y TRIGGERS
-- =====================================================

-- Función para actualizar fecha_actualizacion automáticamente
CREATE OR REPLACE FUNCTION update_fecha_actualizacion()
RETURNS TRIGGER AS $$
BEGIN
    NEW.fecha_actualizacion = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger para cliente
CREATE TRIGGER trigger_cliente_actualizacion
    BEFORE UPDATE ON cliente
    FOR EACH ROW
    EXECUTE FUNCTION update_fecha_actualizacion();

-- Trigger para proveedor
CREATE TRIGGER trigger_proveedor_actualizacion
    BEFORE UPDATE ON proveedor
    FOR EACH ROW
    EXECUTE FUNCTION update_fecha_actualizacion();

-- Trigger para administrador
CREATE TRIGGER trigger_administrador_actualizacion
    BEFORE UPDATE ON administrador
    FOR EACH ROW
    EXECUTE FUNCTION update_fecha_actualizacion();

-- Trigger para servicio
CREATE TRIGGER trigger_servicio_actualizacion
    BEFORE UPDATE ON servicio
    FOR EACH ROW
    EXECUTE FUNCTION update_fecha_actualizacion();

-- Trigger para servicio_proveedor
CREATE TRIGGER trigger_servicio_proveedor_actualizacion
    BEFORE UPDATE ON servicio_proveedor
    FOR EACH ROW
    EXECUTE FUNCTION update_fecha_actualizacion();

-- Trigger para encargo
CREATE TRIGGER trigger_encargo_actualizacion
    BEFORE UPDATE ON encargo
    FOR EACH ROW
    EXECUTE FUNCTION update_fecha_actualizacion();

-- =====================================================
-- COMENTARIOS
-- =====================================================

COMMENT ON TABLE credencial IS 'Entidad exclusiva para gestión de contraseña (SIN email, SIN username)';
COMMENT ON TABLE cliente IS 'Dominio independiente: Cliente del marketplace';
COMMENT ON TABLE proveedor IS 'Dominio independiente: Proveedor de servicios';
COMMENT ON TABLE administrador IS 'Dominio independiente: Administrador del sistema';
COMMENT ON TABLE servicio IS 'Catálogo maestro de servicios';
COMMENT ON TABLE servicio_proveedor IS 'Servicios ofrecidos por cada proveedor';
COMMENT ON TABLE disponibilidad_proveedor IS 'Franjas de disponibilidad del proveedor';
COMMENT ON TABLE encargo IS 'Solicitudes de servicio creadas por clientes (SIN calificación)';
COMMENT ON TABLE calificacion IS 'Calificaciones: entidad separada con relación 1:1 a Encargo';
COMMENT ON TABLE encargo_historial IS 'Historial de cambios de estado de encargos';
COMMENT ON TABLE notificacion IS 'Notificaciones enviadas a usuarios';
COMMENT ON TABLE audit_log IS 'Log de auditoría del sistema';

-- Nota sobre Wilson Score
-- El Wilson Score se calcula asíncronamente en el Search Module
-- NO se persiste en la base de datos, se calcula en tiempo real o desde caché Redis

-- =====================================================
-- FIN DEL ESQUEMA
-- =====================================================
