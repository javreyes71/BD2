-- ============================================================
-- SCRIPT DE CONSULTAS Y VISTAS (ACTUALIZADO A POSTGRESQL Y NUEVO MODELO)
-- ============================================================

-- 1. Vista de Usuarios Clientes
CREATE OR REPLACE VIEW v_usuarios_clientes AS
SELECT Rut, Nombre, Apellido, Correo, Calificacion_promedio
FROM Usuario
WHERE es_cliente = TRUE;

-- 2. Vista de Usuarios Emprendedores
CREATE OR REPLACE VIEW v_usuarios_emprendedores AS
SELECT Rut, Nombre, Apellido, Correo, Calificacion_promedio
FROM Usuario
WHERE es_emprendedor = TRUE;

-- 3. Productos disponibles con su stock y precio
CREATE OR REPLACE VIEW v_productos_disponibles AS
SELECT p.id_producto, p.nombre, p.precio, p.stock, c.Nombre_categoria
FROM Producto p
LEFT JOIN Categoria c ON p.id_categoria = c.id_categoria
WHERE p.disponibilidad = TRUE AND p.stock > 0;

-- 4. Servicios disponibles
CREATE OR REPLACE VIEW v_servicios_disponibles AS
SELECT s.id_servicio, s.nombre, s.precio, c.Nombre_categoria
FROM Servicio s
LEFT JOIN Categoria c ON s.id_categoria = c.id_categoria
WHERE s.disponibilidad = TRUE;

-- 5. Extraer Talla y Color desde atributo JSON de Productos (Vestuario)
CREATE OR REPLACE VIEW v_ropa_atributos AS
SELECT 
    nombre, 
    precio, 
    Atributos->>'talla' AS talla, 
    Atributos->>'color' AS color
FROM Producto
WHERE Atributos->>'talla' IS NOT NULL;

-- 6. Detalle completo de compras por usuario
CREATE OR REPLACE VIEW v_historial_compras AS
SELECT 
    c.id_compra,
    u.Nombre AS comprador,
    c.fecha_compra,
    c.total_pagado,
    p.nombre AS producto_comprado,
    dc.cantidad,
    dc.precio_vendido
FROM Compra c
JOIN Usuario u ON c.id_usuario = u.Rut
JOIN Detalle_Compra dc ON c.id_compra = dc.id_compra
LEFT JOIN Producto p ON dc.id_producto = p.id_producto;

-- 7. Promedio de ventas por categoría
SELECT 
    cat.Nombre_categoria,
    COUNT(dc.id_detalle_compra) AS total_ventas,
    SUM(dc.precio_vendido * dc.cantidad) AS ingresos_totales
FROM Detalle_Compra dc
JOIN Producto p ON dc.id_producto = p.id_producto
JOIN Categoria cat ON p.id_categoria = cat.id_categoria
GROUP BY cat.Nombre_categoria;

-- 8. Clientes con compras mayores al promedio
SELECT u.Rut, u.Nombre, c.total_pagado
FROM Compra c
JOIN Usuario u ON c.id_usuario = u.Rut
WHERE c.total_pagado > (SELECT AVG(total_pagado) FROM Compra);

-- 9. Productos sin ventas (Left Join)
SELECT p.nombre, p.precio
FROM Producto p
LEFT JOIN Detalle_Compra dc ON p.id_producto = dc.id_producto
WHERE dc.id_detalle_compra IS NULL;

-- 10. Cantidad de reseñas por producto
SELECT p.nombre, COUNT(r.id_resena) AS cantidad_resenas, AVG(r.calificacion) AS promedio
FROM Producto p
JOIN Resena r ON p.id_producto = r.id_producto
GROUP BY p.nombre
HAVING COUNT(r.id_resena) > 0;

-- 11. Productos con alerta de stock crítico
SELECT nombre, stock 
FROM Producto 
WHERE stock < 10 
ORDER BY stock ASC;

-- 12. Obtener modalidad de los servicios usando JSON
SELECT nombre, precio, Atributos->>'Modalidad' AS modalidad
FROM Servicio
WHERE Atributos->>'Modalidad' IS NOT NULL;

-- 13. Obtener el medio de pago más utilizado
SELECT mp.tipo_pago, COUNT(c.id_compra) AS usos
FROM Medio_pago mp
JOIN Compra c ON mp.id_medio_pago = c.id_medio_pago
GROUP BY mp.tipo_pago
ORDER BY usos DESC;

-- 14. Cotizaciones pendientes (Vigentes)
SELECT id_cotizacion, fecha_emision, validez_dias, total_estimado
FROM Cotizacion
WHERE fecha_emision + validez_dias >= CURRENT_DATE;

-- 15. Tiempo promedio de entrega de envíos en días (Diferencia de fechas Postgres)
SELECT 
    estado_envio, 
    AVG(fecha_entrega_estimada - fecha_envio) AS dias_promedio_entrega
FROM Envio
WHERE fecha_envio IS NOT NULL AND fecha_entrega_estimada IS NOT NULL
GROUP BY estado_envio;

-- 16. Identificar ventas de fin de semana (Usando ISODOW de Postgres)
SELECT 
    c.id_compra, 
    c.fecha_compra,
    c.total_pagado,
    CASE 
        WHEN EXTRACT(ISODOW FROM c.fecha_compra) IN (6, 7) THEN 'Fin de Semana'
        ELSE 'Día de Semana'
    END AS tipo_dia
FROM Compra c;

-- 17. Top 5 usuarios con mejor calificación promedio
SELECT Rut, Nombre, Apellido, Calificacion_promedio
FROM Usuario
ORDER BY Calificacion_promedio DESC
LIMIT 5;

-- 18. Valorización del inventario por categoría
SELECT 
    c.Nombre_categoria, 
    SUM(p.precio * p.stock) AS valor_inventario
FROM Producto p
JOIN Categoria c ON p.id_categoria = c.id_categoria
GROUP BY c.Nombre_categoria;

-- 19. Compras que aplicaron devolución (Outer Join)
SELECT 
    c.id_compra, c.total_pagado, d.fecha_devolucion, d.motivo
FROM Compra c
LEFT JOIN Devolucion d ON c.id_compra = d.id_compra
WHERE d.id_devolucion IS NOT NULL;

-- 20. Resumen de Seguimiento Logístico de Envíos
SELECT 
    e.id_envio, 
    e.estado_envio, 
    s.fecha_actualizacion, 
    s.ubicacion_actual
FROM Envio e
JOIN Seguimiento s ON e.id_envio = s.id_envio
ORDER BY s.fecha_actualizacion DESC;
