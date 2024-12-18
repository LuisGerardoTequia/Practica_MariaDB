CREATE DATABASE IF NOT EXISTS IndustriaFarmaceutica;
USE IndustriaFarmaceutica;

-- Tabla Medicamentos
CREATE TABLE Medicamentos (
    id INT AUTO_INCREMENT PRIMARY KEY, 
    nombre VARCHAR(200) NOT NULL,
    tipo VARCHAR(200) NOT NULL,
    precio DECIMAL(10,2) NOT NULL,
    stock INT,
    fecha_vencimiento DATE,
    create_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    update_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Tabla Proveedores
CREATE TABLE Proveedores (
    id INT AUTO_INCREMENT PRIMARY KEY,
    nombre VARCHAR(200) NOT NULL,
    pais VARCHAR(200) NOT NULL,
    telefono VARCHAR(200) NOT NULL,
    email VARCHAR(200) NOT NULL,
    raiting DECIMAL(10,2) NOT NULL,
    create_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    update_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Tabla Clientes
CREATE TABLE Clientes (
    id INT AUTO_INCREMENT PRIMARY KEY,
    nombre VARCHAR(200) NOT NULL, 
    direccion VARCHAR(100) NOT NULL,
    telefono VARCHAR(20) NOT NULL,
    email VARCHAR(200) NOT NULL,
    tipo_cliente ENUM('Mayorista', 'Minorista'),
    create_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    update_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Tabla Ventas
CREATE TABLE Ventas (
    id INT AUTO_INCREMENT PRIMARY KEY,
    id_cliente INT,
    id_medicamento INT,
    cantidad INT NOT NULL,
    fecha DATE NOT NULL,
    total DECIMAL(10,2) NOT NULL,
    create_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    update_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (id_cliente) REFERENCES Clientes(id),
    FOREIGN KEY (id_medicamento) REFERENCES Medicamentos(id)
);

-- Tabla Inventarios
CREATE TABLE Inventarios (
    id INT AUTO_INCREMENT PRIMARY KEY,
    id_cliente INT, 
    cantidad INT,
    fecha_actualizacion TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    create_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    update_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Tabla Auditoria
CREATE TABLE Auditoria (
    id INT AUTO_INCREMENT PRIMARY KEY,
    tabla_modificada VARCHAR(200) NOT NULL, 
    accion VARCHAR(200),
    fecha TIMESTAMP,
    usuario VARCHAR(200),
    create_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    update_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);


--- Insertar Datos

INSERT INTO Medicamentos (nombre,tipo,precio,stock,fecha_vencimiento) VALUES ('Paracetamol', 'Analgesico', 2.5, 100, '2025-12-31'),
('Ibuprofeno', 'Anti-inflamatorio', 3.0, 200, '2024-06-30');
INSERT INTO Proveedores (nombre,pais,telefono,email,rating) VALUES ('Proveedor A', 'Colombia', '123456789', 'contacto@proveedora.com', 4.5),
('Proveedor B', 'México', '987654321', 'contacto@proveedorb.com', 4.0);
INSERT INTO Clientes (nombre,direccion,telefono,email,tipo_cliente) VALUES ('Cliente 1', 'Calle 123', '123456789', 'cliente1@gmail.com', 'Mayorista'),
('Cliente 2', 'Carrera 45', '987654321', 'cliente2@gmail.com', 'Minorista');
INSERT INTO Ventas(id_cliente, id_medicamento,cantidad, fecha, total) VALUES 
(1, 1, 50, '2024-09-01', 125.00),
(2, 2, 30, '2024-09-02', 90.00),
(1, 2, 20, '2024-09-05', 60.00);
INSERT INTO Empleados (nombre, puesto,salario, fecha_contratacion, supervisor_id) VALUES ('Juan Perez', 'Vendedor', 2000.00, '2022-01-15', NULL),
('Ana Torres', 'Gerente', 5000.00, '2021-06-10', NULL);


-- Crear Usuarios y Permisos

CREATE USER farmaceutico@localhost IDENTIFIED BY `secures`;
CREATE USER auditor@localhost IDENTIFIED BY `secures`;

GRANT INSERT, DELETE, UPDATE ON IndustriaFarmaceutica.* TO farmaceutico@localhost;
GRANT SELECT ON IndustriaFarmaceutica.* TO auditor@localhost; 


-- Crear Triggers 
--- Trigger para insertar datos en la tabla auditoria
DELIMITER $$
CREATE TRIGGER after_insert_inventario AFTER INSERT ON Invetario FOR EACH ROW
BEGIN
INSERT INTO Auditoria (tabla_modificada,accion, fecha,usuario) VALUES ('Inventarios','INSERT', NOW(),USER());
END $$

--- Trigger para insertar datos en la tabla auditoria cuando se actualizan datos
CREATE TRIGGER after_update_inventario AFTER UPDATE ON Inventario FOR EACH ROW
BEGIN 
INSERT INTO Auditoria (tabla_modificada,accion,fecha, usuario) VALUES ('Inventarios', 'UPDATE', NOW(), USER());
END $$

--- Trigger Eliminar Pedidos
CREATE TRIGGER delete_pedidos BEFORE DELETE ON Pedidos FOR EACH ROW 
BEGIN 
INSERT INTO Auditoria (tabla_modificada, accion, fecha, usuario) VALUES ('Pedidos','DELETE',NOW(), USER());
END $$

--- Trigger Actualizacion de STOCK 
CREATE TRIGGER Update_inventario AFTER INSERT ON Ventas FOR EACH ROW
BEGIN
UPDATE Medicamentos SET stock = stock- NEW.cantidad
WHERE id = NEW.id_medicamento;
END $$
DELIMITER ;


-- Crear Funciones
--- Calcular descuentos
DELIMITER $$
CREATE FUNCTION calcular_descuento (precio DECIMAL (10,2), porcentaje INT)
RETURNS DECIMAL (10,2)
DETERMINISTIC
BEGIN
RETURN precio - (precio* porcentaje /100);
END $$


--CALL FUNCTION calcular_descuento;

--- Calcular el valor total
CREATE FUNCTION calcular_total (cantidad INT, precio DECIMAL (10,2))
RETURNS DECIMAL (10,2)
DETERMINISTIC
BEGIN
RETURN cantidad * precio;
END$$

--- Calcular Promedio Raiting
CREATE FUNCTION promedio_rating()
RETURNS DECIMAL (10,2)
DETERMINISTIC
BEGIN 
RETURN(SELECT AVG(rating) FROM Proveedores);
END$$
DELIMITER ;


-- Generar un join
SELECT c.nombre AS cliente, m.nombre AS medicamento, v.cantidad, v.total
FROM Ventas v 
JOIN Clientes c ON v.id_cliente = c.id
JOIN Medicamentos m ON v.id_medicamento = m.id;

-- Crear Windows Functions

SELECT nombre, salario, RANK() OVER (ORDER BY salario DESC) AS rango
FROM Empleados;

SELECT id_medicamento, SUM(Cantidad) OVER (PARTITION BY id_medicamento) AS total_cantidad
FROM Ventas;


--- Crear CTE 
WITH TotalVentas AS(
SELECT id_medicamento, SUM(total) AS ventas_totales
FROM Ventas
GROUP BY id_medicamento
)
SELECT * FROM TotalVentas;

WITH EmpleadosPorSupervisor AS(
SELECT supervisor_id, COUNT(*) AS Empleados
FROM Empleados
GROUP BY supervisor_id
)
SELECT * FROM EmpleadosPorSupervisor;



--- Crear Procedimientos 
-- Procedimiento Actualizar Stock
DELIMITER $$
CREATE PROCEDURE actualizar_stock(IN id_medicamento INT, IN nueva_cantidad INT)
BEGIN
UPDATE Medicamentos SET stock = nueva_cantidad WHERE id =id_medicamento;
END$$
-- Procedimiento Registrar Pedido
CREATE PROCEDURE registrar_pedido(IN id_proveedor INT, IN id_medicamento INT, IN cantidad INT)
BEGIN
INSERT INTO Pedidos (id_proveedor, id_medicamento, cantidad, CURDATE());
VALUES
END$$
DELIMITER ;

--- Procedimiento Ventas
CREATE PROCEDURE registrar_venta(IN cliente_id INT, IN MEDICAMENTO_id INT, IN )


--- Crear Index 
CREATE INDEX idx_nombre_medicamento ON Medicamentos(nombre);
CREATE INDEX idx_nombre_proveedor ON Proveedores(nombre);


--- Funciones Aritmeticas 
-- Analisis de Ventas
SELECT c.nombre AS cliente, m.nombre AS medicamento,
SUM(v.cantidad)AS total_cantidad,
SUM(v.total) AS total_ventas,
ROUND(AVG(v.total),2) AS promedio_ventas
FROM Ventas v 
JOIN Clientes c ON v.id_cliente = c.id
JOIN Medicamentos m ON v.id_medicamento =m.id
GROUP BY c.nombre, m.nombre;


-- Clasificar Ventas
SELECT v.id_cliente, c.nombre AS cliente,
SUM(v.total) OVER (PARTITION BY v.id_cliente) AS total_ventas_cliente,
RANK() OVER (ORDER BY SUM(v.total) OVER (PARTITION BY v.id_cliente)DESC) AS ranking_ventas
FROM Ventas v 
JOIN Clientes c ON v.id_cliente = c.id
GROUP BY v.id_cliente, c.nombre;








