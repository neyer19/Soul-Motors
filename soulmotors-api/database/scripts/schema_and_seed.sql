-- ==========================================
-- SCRIPT DDL Y SEED v2 - SOUL MOTORS
-- Entorno: Neon (PostgreSQL Cloud)
-- Sprint 1: Tablas base, Auditoría y Triggers
-- ==========================================

-- 0. Función Genérica para actualizado_at
CREATE OR REPLACE FUNCTION actualizar_timestamp()
RETURNS TRIGGER AS $$
BEGIN
    NEW.actualizado_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- 1. Tabla de Auditoría
CREATE TABLE registro_auditoria (
    id BIGSERIAL PRIMARY KEY,
    tabla_afectada VARCHAR(50) NOT NULL,
    accion VARCHAR(20) NOT NULL,
    usuario_id BIGINT,
    detalle JSONB,
    creado_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    actualizado_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
CREATE TRIGGER trg_auditoria_actualizado_at BEFORE UPDATE ON registro_auditoria FOR EACH ROW EXECUTE FUNCTION actualizar_timestamp();

-- 2. Tabla de Usuarios
CREATE TABLE usuario (
    id BIGSERIAL PRIMARY KEY,
    nombre VARCHAR(100) NOT NULL,
    rol VARCHAR(50) NOT NULL CHECK (rol IN ('ADMINISTRADOR', 'EMPLEADO')),
    username VARCHAR(50) UNIQUE NOT NULL,
    password VARCHAR(255) NOT NULL,
    activo BOOLEAN DEFAULT TRUE,
    creado_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    actualizado_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
CREATE TRIGGER trg_usuario_actualizado_at BEFORE UPDATE ON usuario FOR EACH ROW EXECUTE FUNCTION actualizar_timestamp();

-- 3. Tabla de Clientes
CREATE TABLE cliente (
    id BIGSERIAL PRIMARY KEY,
    documento VARCHAR(20) UNIQUE NOT NULL,
    nombre VARCHAR(100) NOT NULL,
    telefono VARCHAR(20),
    creado_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    actualizado_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
CREATE TRIGGER trg_cliente_actualizado_at BEFORE UPDATE ON cliente FOR EACH ROW EXECUTE FUNCTION actualizar_timestamp();

-- 4. Tabla de Vehículos (Relación 1:N con Cliente)
CREATE TABLE vehiculo (
    id BIGSERIAL PRIMARY KEY,
    cliente_id BIGINT NOT NULL,
    placa VARCHAR(20) UNIQUE NOT NULL,
    marca VARCHAR(50) NOT NULL,
    modelo VARCHAR(50) NOT NULL,
    creado_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    actualizado_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_cliente FOREIGN KEY (cliente_id) REFERENCES cliente(id) ON DELETE RESTRICT
);
CREATE TRIGGER trg_vehiculo_actualizado_at BEFORE UPDATE ON vehiculo FOR EACH ROW EXECUTE FUNCTION actualizar_timestamp();

-- 5. Tabla de Piezas (Catálogo e Inventario)
CREATE TABLE pieza (
    id BIGSERIAL PRIMARY KEY,
    sku VARCHAR(50) UNIQUE NOT NULL,
    nombre VARCHAR(100) NOT NULL,
    categoria VARCHAR(50) NOT NULL CHECK (categoria IN ('Repuesto', 'Accesorio')),
    precio_venta DECIMAL(10,2) NOT NULL,
    stock_actual INT NOT NULL CHECK (stock_actual >= 0),
    stock_minimo INT NOT NULL,
    creado_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    actualizado_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
CREATE TRIGGER trg_pieza_actualizado_at BEFORE UPDATE ON pieza FOR EACH ROW EXECUTE FUNCTION actualizar_timestamp();

-- 6. Tabla Movimiento_Inventario
CREATE TABLE movimiento_inventario (
    id BIGSERIAL PRIMARY KEY,
    id_pieza BIGINT NOT NULL,
    tipo_movimiento VARCHAR(20) NOT NULL CHECK (tipo_movimiento IN ('Entrada', 'Salida')),
    cantidad INT NOT NULL,
    creado_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    actualizado_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_mov_pieza FOREIGN KEY (id_pieza) REFERENCES pieza(id) ON DELETE RESTRICT
);
CREATE TRIGGER trg_mov_inv_actualizado_at BEFORE UPDATE ON movimiento_inventario FOR EACH ROW EXECUTE FUNCTION actualizar_timestamp();

-- ==========================================
-- TAREA S1-T01B: PROVEEDORES Y PIEZA_PROVEEDOR
-- Entorno: Neon (PostgreSQL Cloud)
-- ==========================================

-- 1. Tabla de Proveedores
CREATE TABLE proveedor (
    id BIGSERIAL PRIMARY KEY,
    nit VARCHAR(20) UNIQUE NOT NULL,
    nombre VARCHAR(100) NOT NULL,
    telefono VARCHAR(20),
    email VARCHAR(100),
    direccion VARCHAR(150),
    tiempo_entrega_dias INT NOT NULL CHECK (tiempo_entrega_dias >= 0),
    activo BOOLEAN DEFAULT TRUE,
    creado_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    actualizado_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TRIGGER trg_proveedor_actualizado_at 
BEFORE UPDATE ON proveedor 
FOR EACH ROW EXECUTE FUNCTION actualizar_timestamp();

-- 2. Tabla Intermedia Pieza_Proveedor (Relación N:M con Prioridad y Costo)
CREATE TABLE pieza_proveedor (
    id BIGSERIAL PRIMARY KEY,
    id_pieza BIGINT NOT NULL,
    id_proveedor BIGINT NOT NULL,
    prioridad INT NOT NULL CHECK (prioridad >= 1),
    costo_pactado DECIMAL(10,2) NOT NULL CHECK (costo_pactado >= 0),
    creado_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    actualizado_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    -- Restricciones de Integridad
    CONSTRAINT fk_pp_pieza FOREIGN KEY (id_pieza) REFERENCES pieza(id) ON DELETE CASCADE,
    CONSTRAINT fk_pp_proveedor FOREIGN KEY (id_proveedor) REFERENCES proveedor(id) ON DELETE RESTRICT,
    -- Evita asignar el mismo proveedor dos veces a la misma pieza
    CONSTRAINT uq_pieza_proveedor UNIQUE (id_pieza, id_proveedor),
    -- Evita dos proveedores con el mismo nivel de prioridad para una misma pieza
    CONSTRAINT uq_pieza_prioridad UNIQUE (id_pieza, prioridad)
);

CREATE TRIGGER trg_pieza_proveedor_actualizado_at 
BEFORE UPDATE ON pieza_proveedor 
FOR EACH ROW EXECUTE FUNCTION actualizar_timestamp();




-- ==========================================
-- DATOS SEMILLA (SEED DATA)
-- ==========================================


INSERT INTO usuario (nombre, rol, username, password) VALUES
('Admin General', 'ADMINISTRADOR', 'admin', 'hashed_pass_1'),
('Mecánico Juan', 'EMPLEADO', 'empleado1', 'hashed_pass_2');

INSERT INTO cliente (documento, nombre, telefono) VALUES
('10101010', 'Carlos Pérez', '3001234567');

INSERT INTO vehiculo (cliente_id, placa, marca, modelo) VALUES
(1, 'AAA123', 'Yamaha', 'FZ25');

INSERT INTO pieza (sku, nombre, categoria, precio_venta, stock_actual, stock_minimo) VALUES
('REP-001', 'Pastillas de Freno', 'Repuesto', 45000.00, 10, 2),
('ACC-001', 'Casco Integral', 'Accesorio', 120000.00, 5, 1);

-- ==========================================
-- DATOS SEMILLA (SEED DATA) - S1-T01B
-- ==========================================

INSERT INTO proveedor (nit, nombre, telefono, email, direccion, tiempo_entrega_dias) VALUES
('900123456-1', 'Distribuidora Motopartes S.A.S.', '3105550199', 'ventas@motopartes.com', 'Calle 13 # 24-50, Bogotá', 2),
('800987654-2', 'Importadora Yamaha & Racing', '3204448877', 'pedidos@yamaharacing.co', 'Av. Boyacá # 68-12, Bogotá', 5);

-- Asociamos las piezas existentes (id 1 = Pastillas de Freno, id 2 = Casco Integral)
INSERT INTO pieza_proveedor (id_pieza, id_proveedor, prioridad, costo_pactado) VALUES
(1, 1, 1, 28000.00), -- Proveedor principal (Prioridad 1) para Pastillas de Freno
(1, 2, 2, 31000.00), -- Proveedor secundario (Prioridad 2) para Pastillas de Freno
(2, 2, 1, 85000.00); -- Proveedor principal (Prioridad 1) para Casco Integral