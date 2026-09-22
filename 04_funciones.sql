SET search_path TO public;

-- ============================================================
-- ETAPA 8: PROGRAMACIÓN EN BASE DE DATOS — FUNCIONES PL/pgSQL
-- 50% de las 69 consultas del enunciado = 35 funciones dinámicas
-- + CRUD por tabla + Triggers + Cursor FOR UPDATE
-- ============================================================

-- ************************************************************
-- SECCIÓN 1: CONSOLIDACIÓN TEMPORAL Y VOLUMETRÍA (9 enunciados → 9 funciones)
-- ************************************************************

-- 1.1 Cuántos clientes compraron un producto X en un período
CREATE OR REPLACE FUNCTION fn_count_clientes_producto(VARCHAR, DATE, DATE)
RETURNS INT AS $$
DECLARE
    p_producto ALIAS FOR $1;
    p_desde    ALIAS FOR $2;
    p_hasta    ALIAS FOR $3;
    total      INT := 0;
BEGIN
    SELECT COUNT(DISTINCT c.rut) INTO total
    FROM Compra c
    JOIN Detalle_Compra dc ON c.id_compra = dc.id_compra
    JOIN Producto p ON dc.id_producto = p.id_producto
    WHERE p.nombre ILIKE '%' || p_producto || '%'
      AND c.fecha_compra BETWEEN p_desde AND p_hasta;
    IF NOT FOUND THEN RAISE NOTICE 'Sin resultados para producto %', p_producto; END IF;
    RETURN total;
END;
$$ LANGUAGE plpgsql;
-- PRUEBA: SELECT fn_count_clientes_producto('Laptop', '2025-01-01', '2026-12-31');

-- 1.2 Listar clientes que compraron un producto X en un período
CREATE OR REPLACE FUNCTION fn_clientes_producto(VARCHAR, DATE, DATE)
RETURNS TABLE(rut VARCHAR, nombre VARCHAR, apellido VARCHAR, fecha DATE) AS $$
DECLARE
    p_producto ALIAS FOR $1;
    p_desde    ALIAS FOR $2;
    p_hasta    ALIAS FOR $3;
BEGIN
    RETURN QUERY
        SELECT DISTINCT u.Rut, u.Nombre, u.Apellido, c.fecha_compra
        FROM Usuario u
        JOIN Compra c ON u.Rut = c.rut
        JOIN Detalle_Compra dc ON c.id_compra = dc.id_compra
        JOIN Producto p ON dc.id_producto = p.id_producto
        WHERE p.nombre ILIKE '%' || p_producto || '%'
          AND c.fecha_compra BETWEEN p_desde AND p_hasta;
    RETURN;
END;
$$ LANGUAGE plpgsql;
-- PRUEBA: SELECT * FROM fn_clientes_producto('Laptop', '2025-01-01', '2026-12-31') LIMIT 10;

-- 1.3 Cuántos clientes compraron un servicio X en un período
CREATE OR REPLACE FUNCTION fn_count_clientes_servicio(VARCHAR, DATE, DATE)
RETURNS INT AS $$
DECLARE
    p_servicio ALIAS FOR $1;
    p_desde    ALIAS FOR $2;
    p_hasta    ALIAS FOR $3;
    total      INT := 0;
BEGIN
    SELECT COUNT(DISTINCT c.rut) INTO total
    FROM Compra c
    JOIN Detalle_Compra dc ON c.id_compra = dc.id_compra
    JOIN Servicio s ON dc.id_servicio = s.id_servicio
    WHERE s.nombre ILIKE '%' || p_servicio || '%'
      AND c.fecha_compra BETWEEN p_desde AND p_hasta;
    RETURN total;
END;
$$ LANGUAGE plpgsql;
-- PRUEBA: SELECT fn_count_clientes_servicio('Mantenimiento', '2025-01-01', '2026-12-31');

-- 1.4 Listar clientes que compraron un servicio X en un período
CREATE OR REPLACE FUNCTION fn_clientes_servicio(VARCHAR, DATE, DATE)
RETURNS TABLE(rut VARCHAR, nombre VARCHAR, apellido VARCHAR, fecha DATE) AS $$
DECLARE
    p_servicio ALIAS FOR $1;
    p_desde    ALIAS FOR $2;
    p_hasta    ALIAS FOR $3;
BEGIN
    RETURN QUERY
        SELECT DISTINCT u.Rut, u.Nombre, u.Apellido, c.fecha_compra
        FROM Usuario u
        JOIN Compra c ON u.Rut = c.rut
        JOIN Detalle_Compra dc ON c.id_compra = dc.id_compra
        JOIN Servicio s ON dc.id_servicio = s.id_servicio
        WHERE s.nombre ILIKE '%' || p_servicio || '%'
          AND c.fecha_compra BETWEEN p_desde AND p_hasta;
    RETURN;
END;
$$ LANGUAGE plpgsql;
-- PRUEBA: SELECT * FROM fn_clientes_servicio('Instalacion', '2025-01-01', '2026-12-31') LIMIT 10;

-- 1.5 Total compras y total pagado del mes actual por cliente X, con flag descuento si >5 compras
CREATE OR REPLACE FUNCTION fn_resumen_mes_cliente(VARCHAR)
RETURNS TABLE(rut VARCHAR, total_compras BIGINT, total_pagado DECIMAL, aplica_descuento BOOLEAN) AS $$
DECLARE
    p_rut ALIAS FOR $1;
BEGIN
    RETURN QUERY
        SELECT c.rut,
               COUNT(c.id_compra),
               COALESCE(SUM(c.total_pagado), 0),
               CASE WHEN COUNT(c.id_compra) > 5 THEN TRUE ELSE FALSE END
        FROM Compra c
        WHERE c.rut = p_rut
          AND EXTRACT(MONTH FROM c.fecha_compra) = EXTRACT(MONTH FROM CURRENT_DATE)
          AND EXTRACT(YEAR FROM c.fecha_compra) = EXTRACT(YEAR FROM CURRENT_DATE)
        GROUP BY c.rut;
    RETURN;
END;
$$ LANGUAGE plpgsql;
-- PRUEBA: SELECT * FROM fn_resumen_mes_cliente('10000233-8');

-- 1.6 Total de ventas del mes por artículo y por vendedor, totalizando al vendedor
CREATE OR REPLACE FUNCTION fn_ventas_mes_vendedor(VARCHAR)
RETURNS TABLE(vendedor VARCHAR, producto VARCHAR, cantidad_vendida BIGINT, total_vendido DECIMAL) AS $$
DECLARE
    p_rut ALIAS FOR $1;
BEGIN
    RETURN QUERY
        SELECT u.Nombre, p.nombre,
               SUM(dc.cantidad),
               SUM(dc.cantidad * dc.precio_vendido)
        FROM Producto p
        JOIN Detalle_Compra dc ON p.id_producto = dc.id_producto
        JOIN Compra c ON dc.id_compra = c.id_compra
        JOIN Usuario u ON p.rut = u.Rut
        WHERE p.rut = p_rut
        GROUP BY ROLLUP(u.Nombre, p.nombre);
    RETURN;
END;
$$ LANGUAGE plpgsql;
-- PRUEBA: SELECT * FROM fn_ventas_mes_vendedor('10000233-8') LIMIT 10;

-- 1.7 Ventas fin de semana vs días hábiles
CREATE OR REPLACE FUNCTION fn_ventas_finde_vs_semana()
RETURNS TABLE(tipo_dia TEXT, cantidad BIGINT, total DECIMAL) AS $$
BEGIN
    RETURN QUERY
        SELECT
            CASE WHEN EXTRACT(ISODOW FROM c.fecha_compra) IN (6,7) THEN 'Fin de Semana' ELSE 'Dia Habil' END,
            COUNT(*),
            SUM(c.total_pagado)
        FROM Compra c
        GROUP BY CASE WHEN EXTRACT(ISODOW FROM c.fecha_compra) IN (6,7) THEN 'Fin de Semana' ELSE 'Dia Habil' END;
    RETURN;
END;
$$ LANGUAGE plpgsql;
-- PRUEBA: SELECT * FROM fn_ventas_finde_vs_semana();

-- 1.8 Variación porcentual de ingresos entre mes actual y mes anterior
CREATE OR REPLACE FUNCTION fn_variacion_mensual()
RETURNS TABLE(mes_actual DECIMAL, mes_anterior DECIMAL, variacion_pct DECIMAL) AS $$
DECLARE
    v_actual   DECIMAL := 0;
    v_anterior DECIMAL := 0;
BEGIN
    SELECT COALESCE(SUM(total_pagado), 0) INTO v_actual FROM Compra
    WHERE EXTRACT(MONTH FROM fecha_compra) = EXTRACT(MONTH FROM CURRENT_DATE)
      AND EXTRACT(YEAR FROM fecha_compra) = EXTRACT(YEAR FROM CURRENT_DATE);

    SELECT COALESCE(SUM(total_pagado), 0) INTO v_anterior FROM Compra
    WHERE EXTRACT(MONTH FROM fecha_compra) = EXTRACT(MONTH FROM CURRENT_DATE) - 1
      AND EXTRACT(YEAR FROM fecha_compra) = EXTRACT(YEAR FROM CURRENT_DATE);

    mes_actual := v_actual;
    mes_anterior := v_anterior;
    IF v_anterior > 0 THEN
        variacion_pct := ROUND(((v_actual - v_anterior) / v_anterior) * 100, 2);
    ELSE
        variacion_pct := NULL;
    END IF;
    RETURN NEXT;
    RETURN;
END;
$$ LANGUAGE plpgsql;
-- PRUEBA: SELECT * FROM fn_variacion_mensual();

-- 1.9 Ventas del último trimestre con descuento aplicado
CREATE OR REPLACE FUNCTION fn_ventas_con_descuento()
RETURNS TABLE(id_compra INT, fecha DATE, total DECIMAL, descuento DECIMAL, nombre_producto VARCHAR) AS $$
BEGIN
    RETURN QUERY
        SELECT c.id_compra, c.fecha_compra, c.total_pagado, o.Porcentaje_descuento, p.nombre
        FROM Compra c
        JOIN Detalle_Compra dc ON c.id_compra = dc.id_compra
        JOIN Producto p ON dc.id_producto = p.id_producto
        JOIN Oferta o ON p.id_oferta = o.id_oferta
        WHERE c.fecha_compra >= CURRENT_DATE - INTERVAL '3 months';
    RETURN;
END;
$$ LANGUAGE plpgsql;
-- PRUEBA: SELECT * FROM fn_ventas_con_descuento() LIMIT 10;


-- ************************************************************
-- SECCIÓN 2: GEORREFERENCIACIÓN Y LOGÍSTICA (8 → 5 funciones)
-- ************************************************************

-- 2.1 Ciudades donde se ha realizado un servicio X
CREATE OR REPLACE FUNCTION fn_ciudades_servicio(VARCHAR)
RETURNS TABLE(comuna VARCHAR, servicio VARCHAR) AS $$
DECLARE
    p_servicio ALIAS FOR $1;
BEGIN
    RETURN QUERY
        SELECT com.Nombre::VARCHAR, s.nombre
        FROM Servicio s
        JOIN Detalle_Compra dc ON s.id_servicio = dc.id_servicio
        JOIN Compra c ON dc.id_compra = c.id_compra
        JOIN Direccion d ON c.rut = d.rut
        JOIN Comuna com ON d.id_comuna = com.ID
        WHERE s.nombre ILIKE '%' || p_servicio || '%'
        GROUP BY com.Nombre, s.nombre;
    RETURN;
END;
$$ LANGUAGE plpgsql;
-- PRUEBA: SELECT * FROM fn_ciudades_servicio('Mantenimiento') LIMIT 10;

-- 2.2 Ciudades donde se ha enviado un producto X
CREATE OR REPLACE FUNCTION fn_ciudades_producto_enviado(VARCHAR)
RETURNS TABLE(comuna VARCHAR, producto VARCHAR) AS $$
DECLARE
    p_producto ALIAS FOR $1;
BEGIN
    RETURN QUERY
        SELECT com.Nombre::VARCHAR, p.nombre
        FROM Producto p
        JOIN Detalle_Compra dc ON p.id_producto = dc.id_producto
        JOIN Compra c ON dc.id_compra = c.id_compra
        JOIN Envio e ON c.id_compra = e.id_compra
        JOIN Direccion d ON e.id_direccion = d.id_direccion
        JOIN Comuna com ON d.id_comuna = com.ID
        WHERE p.nombre ILIKE '%' || p_producto || '%'
        GROUP BY com.Nombre, p.nombre;
    RETURN;
END;
$$ LANGUAGE plpgsql;
-- PRUEBA: SELECT * FROM fn_ciudades_producto_enviado('Laptop') LIMIT 10;

-- 2.3 Productos con despacho pendiente por vendedor
CREATE OR REPLACE FUNCTION fn_despacho_pendiente(VARCHAR DEFAULT NULL)
RETURNS TABLE(vendedor VARCHAR, producto VARCHAR, estado VARCHAR) AS $$
DECLARE
    p_rut ALIAS FOR $1;
BEGIN
    RETURN QUERY
        SELECT u.Nombre, p.nombre, e.estado_envio
        FROM Producto p
        JOIN Detalle_Compra dc ON p.id_producto = dc.id_producto
        JOIN Compra c ON dc.id_compra = c.id_compra
        JOIN Envio e ON c.id_compra = e.id_compra
        JOIN Usuario u ON p.rut = u.Rut
        WHERE e.estado_envio IN ('Recibido', 'En Preparación')
          AND (p_rut IS NULL OR p.rut = p_rut);
    RETURN;
END;
$$ LANGUAGE plpgsql;
-- PRUEBA: SELECT * FROM fn_despacho_pendiente() LIMIT 10;

-- 2.4 Tiempo promedio de tránsito por empresa de transporte
CREATE OR REPLACE FUNCTION fn_tiempo_transito()
RETURNS TABLE(empresa VARCHAR, dias_promedio DECIMAL) AS $$
BEGIN
    RETURN QUERY
        SELECT s.Empresa_transporte,
               ROUND(AVG(e.fecha_entrega_estimada - e.fecha_envio)::DECIMAL, 1)
        FROM Envio e
        JOIN Seguimiento s ON e.codigo_seguimiento = s.Codigo_seguimiento
        WHERE e.fecha_envio IS NOT NULL AND e.fecha_entrega_estimada IS NOT NULL
        GROUP BY s.Empresa_transporte
        ORDER BY AVG(e.fecha_entrega_estimada - e.fecha_envio) DESC;
    RETURN;
END;
$$ LANGUAGE plpgsql;
-- PRUEBA: SELECT * FROM fn_tiempo_transito();

-- 2.6 Envíos sin seguimiento (código nulo)
CREATE OR REPLACE FUNCTION fn_envios_sin_seguimiento()
RETURNS TABLE(id_envio VARCHAR, estado VARCHAR, fecha_envio DATE) AS $$
BEGIN
    RETURN QUERY
        SELECT e.id_envio, e.estado_envio, e.fecha_envio
        FROM Envio e
        WHERE e.codigo_seguimiento IS NULL;
    RETURN;
END;
$$ LANGUAGE plpgsql;
-- PRUEBA: SELECT * FROM fn_envios_sin_seguimiento() LIMIT 10;


-- ************************************************************
-- SECCIÓN 3: FIDELIZACIÓN, VALORACIONES Y DESEMPEÑO (10 → 7 funciones)
-- ************************************************************

-- 3.1 Producto más vendido por cada vendedor
CREATE OR REPLACE FUNCTION fn_producto_top_vendedor(VARCHAR DEFAULT NULL)
RETURNS TABLE(vendedor VARCHAR, rut_vendedor VARCHAR, producto VARCHAR, unidades BIGINT) AS $$
DECLARE
    p_rut ALIAS FOR $1;
BEGIN
    RETURN QUERY
        SELECT DISTINCT ON (p.rut) u.Nombre, p.rut, p.nombre, SUM(dc.cantidad)
        FROM Producto p
        JOIN Detalle_Compra dc ON p.id_producto = dc.id_producto
        JOIN Usuario u ON p.rut = u.Rut
        WHERE (p_rut IS NULL OR p.rut = p_rut)
        GROUP BY p.rut, u.Nombre, p.nombre
        ORDER BY p.rut, SUM(dc.cantidad) DESC;
    RETURN;
END;
$$ LANGUAGE plpgsql;
-- PRUEBA: SELECT * FROM fn_producto_top_vendedor() LIMIT 10;

-- 3.3 Preguntas sin responder de un producto
CREATE OR REPLACE FUNCTION fn_preguntas_sin_responder(INT DEFAULT NULL)
RETURNS TABLE(id_producto INT, producto VARCHAR, id_pregunta VARCHAR, pregunta VARCHAR) AS $$
DECLARE
    p_id ALIAS FOR $1;
BEGIN
    RETURN QUERY
        SELECT p.id_producto, p.nombre, pr.id_pregunta, pr.Texto_pregunta
        FROM Trata_Pregunta_Producto tpp
        JOIN Producto p ON tpp.id_producto = p.id_producto
        JOIN Pregunta pr ON tpp.id_pregunta = pr.id_pregunta
        WHERE pr.Estado = 'Pendiente'
          AND (p_id IS NULL OR p.id_producto = p_id);
    RETURN;
END;
$$ LANGUAGE plpgsql;
-- PRUEBA: SELECT * FROM fn_preguntas_sin_responder() LIMIT 10;

-- 3.4 Productos de un vendedor X con calificación >= 4
CREATE OR REPLACE FUNCTION fn_productos_bien_calificados(VARCHAR)
RETURNS TABLE(producto VARCHAR, puntaje_promedio DECIMAL) AS $$
DECLARE
    p_rut ALIAS FOR $1;
BEGIN
    RETURN QUERY
        SELECT p.nombre, ROUND(AVG(r.puntaje)::DECIMAL, 2)
        FROM Producto p
        JOIN Resena r ON p.id_producto = r.id_producto
        WHERE p.rut = p_rut
        GROUP BY p.nombre
        HAVING AVG(r.puntaje) >= 4
        ORDER BY AVG(r.puntaje) DESC;
    RETURN;
END;
$$ LANGUAGE plpgsql;
-- PRUEBA: SELECT * FROM fn_productos_bien_calificados('10000233-8') LIMIT 10;

-- 3.5 Emprendedores con calificación promedio < 3
CREATE OR REPLACE FUNCTION fn_emprendedores_baja_calificacion()
RETURNS TABLE(rut VARCHAR, nombre VARCHAR, promedio DECIMAL) AS $$
BEGIN
    RETURN QUERY
        SELECT u.Rut, u.Nombre, u.Calificacion_promedio
        FROM Usuario u
        WHERE u.es_emprendedor = TRUE
          AND u.Calificacion_promedio IS NOT NULL
          AND u.Calificacion_promedio < 3
        ORDER BY u.Calificacion_promedio ASC;
    RETURN;
END;
$$ LANGUAGE plpgsql;
-- PRUEBA: SELECT * FROM fn_emprendedores_baja_calificacion() LIMIT 10;

-- 3.7 Reseñas que contengan palabras clave (LIKE)
CREATE OR REPLACE FUNCTION fn_resenas_keyword(VARCHAR)
RETURNS TABLE(producto VARCHAR, puntaje INT, comentario TEXT) AS $$
DECLARE
    p_keyword ALIAS FOR $1;
BEGIN
    RETURN QUERY
        SELECT p.nombre, r.puntaje, r.comentario
        FROM Resena r
        JOIN Producto p ON r.id_producto = p.id_producto
        WHERE r.comentario ILIKE '%' || p_keyword || '%';
    RETURN;
END;
$$ LANGUAGE plpgsql;
-- PRUEBA: SELECT * FROM fn_resenas_keyword('excelente') LIMIT 10;

-- 3.8 Clientes con más de N calificaciones
CREATE OR REPLACE FUNCTION fn_clientes_mas_resenas(INT DEFAULT 10)
RETURNS TABLE(rut VARCHAR, nombre VARCHAR, total_resenas BIGINT) AS $$
DECLARE
    p_min ALIAS FOR $1;
BEGIN
    RETURN QUERY
        SELECT u.Rut, u.Nombre, COUNT(r.id_resena)
        FROM Usuario u
        JOIN Resena r ON u.Rut = r.rut_cliente
        GROUP BY u.Rut, u.Nombre
        HAVING COUNT(r.id_resena) > p_min
        ORDER BY COUNT(r.id_resena) DESC;
    RETURN;
END;
$$ LANGUAGE plpgsql;
-- PRUEBA: SELECT * FROM fn_clientes_mas_resenas(3) LIMIT 10;

-- 3.9 Tiempo de respuesta promedio de emprendedor en preguntas
CREATE OR REPLACE FUNCTION fn_tiempo_respuesta_preguntas(VARCHAR DEFAULT NULL)
RETURNS TABLE(rut_emprendedor VARCHAR, nombre VARCHAR, dias_promedio DECIMAL) AS $$
DECLARE
    p_rut ALIAS FOR $1;
BEGIN
    RETURN QUERY
        SELECT p2.rut, u.Nombre,
               ROUND(AVG(pr.Fecha_respuesta - pr.Fecha_pregunta)::DECIMAL, 1)
        FROM Pregunta pr
        JOIN Trata_Pregunta_Producto tpp ON pr.id_pregunta = tpp.id_pregunta
        JOIN Producto p2 ON tpp.id_producto = p2.id_producto
        JOIN Usuario u ON p2.rut = u.Rut
        WHERE pr.Estado = 'Respondida'
          AND pr.Fecha_respuesta IS NOT NULL
          AND (p_rut IS NULL OR p2.rut = p_rut)
        GROUP BY p2.rut, u.Nombre;
    RETURN;
END;
$$ LANGUAGE plpgsql;
-- PRUEBA: SELECT * FROM fn_tiempo_respuesta_preguntas() LIMIT 10;


-- ************************************************************
-- SECCIÓN 4: MANIPULACIÓN JSON (6 → 4 funciones)
-- ************************************************************

-- 4.1 Material principal de productos de vestuario
CREATE OR REPLACE FUNCTION fn_json_material_vestuario()
RETURNS TABLE(producto VARCHAR, material TEXT, talla TEXT, color TEXT) AS $$
BEGIN
    RETURN QUERY
        SELECT p.nombre,
               p.Atributos->>'material' AS material,
               p.Atributos->>'talla' AS talla,
               p.Atributos->>'color' AS color
        FROM Producto p
        WHERE p.Atributos->>'talla' IS NOT NULL;
    RETURN;
END;
$$ LANGUAGE plpgsql;
-- PRUEBA: SELECT * FROM fn_json_material_vestuario() LIMIT 10;

-- 4.2 Servicios con modalidad remota (JSON)
CREATE OR REPLACE FUNCTION fn_json_servicios_modalidad(VARCHAR)
RETURNS TABLE(servicio VARCHAR, precio DECIMAL, modalidad TEXT) AS $$
DECLARE
    p_modalidad ALIAS FOR $1;
BEGIN
    RETURN QUERY
        SELECT s.nombre, s.precio, s.Atributos->>'Modalidad'
        FROM Servicio s
        WHERE s.Atributos->>'Modalidad' = p_modalidad;
    RETURN;
END;
$$ LANGUAGE plpgsql;
-- PRUEBA: SELECT * FROM fn_json_servicios_modalidad('Remoto') LIMIT 10;

-- 4.4 Productos tecnológicos sin Garantía en JSON
CREATE OR REPLACE FUNCTION fn_json_sin_garantia()
RETURNS TABLE(producto VARCHAR, precio DECIMAL, categoria VARCHAR) AS $$
BEGIN
    RETURN QUERY
        SELECT p.nombre, p.precio, c.Nombre_categoria
        FROM Producto p
        JOIN Categoria c ON p.id_categoria = c.id_categoria
        WHERE c.Nombre_categoria = 'Computación'
          AND (p.Atributos->>'garantia') IS NULL;
    RETURN;
END;
$$ LANGUAGE plpgsql;
-- PRUEBA: SELECT * FROM fn_json_sin_garantia() LIMIT 10;

-- 4.5 Vista desnormalizada de color y talla desde JSON
CREATE OR REPLACE FUNCTION fn_json_variantes_producto()
RETURNS TABLE(id INT, producto VARCHAR, precio DECIMAL, talla TEXT, color TEXT) AS $$
BEGIN
    RETURN QUERY
        SELECT p.id_producto, p.nombre, p.precio,
               p.Atributos->>'talla',
               p.Atributos->>'color'
        FROM Producto p
        WHERE p.Atributos->>'talla' IS NOT NULL
           OR p.Atributos->>'color' IS NOT NULL;
    RETURN;
END;
$$ LANGUAGE plpgsql;
-- PRUEBA: SELECT * FROM fn_json_variantes_producto() LIMIT 10;


-- ************************************************************
-- SECCIÓN 5: EXCLUSIÓN, CONJUNTOS Y CORRELACIONADAS (9 → 5 funciones)
-- ************************************************************

-- 5.1 Servicios no contratados en el mes X
CREATE OR REPLACE FUNCTION fn_servicios_no_contratados(INT, INT DEFAULT NULL)
RETURNS TABLE(servicio VARCHAR, precio DECIMAL) AS $$
DECLARE
    p_mes  ALIAS FOR $1;
    p_anio ALIAS FOR $2;
    v_anio INT;
BEGIN
    v_anio := COALESCE(p_anio, EXTRACT(YEAR FROM CURRENT_DATE)::INT);
    RETURN QUERY
        SELECT s.nombre, s.precio
        FROM Servicio s
        WHERE s.id_servicio NOT IN (
            SELECT dc.id_servicio FROM Detalle_Compra dc
            JOIN Compra c ON dc.id_compra = c.id_compra
            WHERE dc.id_servicio IS NOT NULL
              AND EXTRACT(MONTH FROM c.fecha_compra) = p_mes
              AND EXTRACT(YEAR FROM c.fecha_compra) = v_anio
        );
    RETURN;
END;
$$ LANGUAGE plpgsql;
-- PRUEBA: SELECT * FROM fn_servicios_no_contratados(6) LIMIT 10;

-- 5.3 Clientes a los que un vendedor X ha vendido
CREATE OR REPLACE FUNCTION fn_clientes_de_vendedor(VARCHAR)
RETURNS TABLE(rut_cliente VARCHAR, nombre VARCHAR, total_comprado DECIMAL) AS $$
DECLARE
    p_rut ALIAS FOR $1;
BEGIN
    RETURN QUERY
        SELECT DISTINCT u.Rut, u.Nombre, SUM(dc.precio_vendido * dc.cantidad)
        FROM Producto p
        JOIN Detalle_Compra dc ON p.id_producto = dc.id_producto
        JOIN Compra c ON dc.id_compra = c.id_compra
        JOIN Usuario u ON c.rut = u.Rut
        WHERE p.rut = p_rut
        GROUP BY u.Rut, u.Nombre;
    RETURN;
END;
$$ LANGUAGE plpgsql;
-- PRUEBA: SELECT * FROM fn_clientes_de_vendedor('10000233-8') LIMIT 10;

-- 5.4 Usuarios con rol dual (cliente y emprendedor simultáneamente)
CREATE OR REPLACE FUNCTION fn_usuarios_dual()
RETURNS TABLE(rut VARCHAR, nombre VARCHAR, apellido VARCHAR) AS $$
BEGIN
    RETURN QUERY
        SELECT u.Rut, u.Nombre, u.Apellido
        FROM Usuario u
        WHERE u.es_cliente = TRUE AND u.es_emprendedor = TRUE;
    RETURN;
END;
$$ LANGUAGE plpgsql;
-- PRUEBA: SELECT * FROM fn_usuarios_dual() LIMIT 10;

-- 5.5 Clientes con wishlist pero sin compras (NOT IN)
CREATE OR REPLACE FUNCTION fn_wishlist_sin_compras()
RETURNS TABLE(rut VARCHAR, nombre VARCHAR, items_wishlist BIGINT) AS $$
BEGIN
    RETURN QUERY
        SELECT u.Rut, u.Nombre, COUNT(w.id_wishlist)
        FROM Usuario u
        JOIN Wishlist w ON u.Rut = w.rut
        WHERE u.Rut NOT IN (SELECT c.rut FROM Compra c)
        GROUP BY u.Rut, u.Nombre;
    RETURN;
END;
$$ LANGUAGE plpgsql;
-- PRUEBA: SELECT * FROM fn_wishlist_sin_compras() LIMIT 10;

-- 5.9 Productos comprados juntos frecuentemente
CREATE OR REPLACE FUNCTION fn_productos_comprados_juntos()
RETURNS TABLE(producto_a VARCHAR, producto_b VARCHAR, veces_juntos BIGINT) AS $$
BEGIN
    RETURN QUERY
        SELECT p1.nombre, p2.nombre, COUNT(*)
        FROM Detalle_Compra dc1
        JOIN Detalle_Compra dc2 ON dc1.id_compra = dc2.id_compra AND dc1.id_producto < dc2.id_producto
        JOIN Producto p1 ON dc1.id_producto = p1.id_producto
        JOIN Producto p2 ON dc2.id_producto = p2.id_producto
        WHERE dc1.id_producto IS NOT NULL AND dc2.id_producto IS NOT NULL
        GROUP BY p1.nombre, p2.nombre
        HAVING COUNT(*) > 1
        ORDER BY COUNT(*) DESC;
    RETURN;
END;
$$ LANGUAGE plpgsql;
-- PRUEBA: SELECT * FROM fn_productos_comprados_juntos() LIMIT 10;


-- ************************************************************
-- SECCIÓN 6: INVENTARIO, COTIZACIONES Y RETORNOS (8 → 3 funciones)
-- ************************************************************

-- 6.1 Productos con devoluciones por cliente y motivo
CREATE OR REPLACE FUNCTION fn_devoluciones_cliente(VARCHAR DEFAULT NULL)
RETURNS TABLE(cliente VARCHAR, producto VARCHAR, motivo VARCHAR, estado VARCHAR) AS $$
DECLARE
    p_rut ALIAS FOR $1;
BEGIN
    RETURN QUERY
        SELECT u.Nombre, p.nombre, d.motivo, d.estado_devolucion
        FROM Devolucion d
        JOIN Compra c ON d.id_compra = c.id_compra
        JOIN Detalle_Compra dc ON c.id_compra = dc.id_compra
        JOIN Producto p ON dc.id_producto = p.id_producto
        JOIN Usuario u ON d.rut = u.Rut
        WHERE (p_rut IS NULL OR d.rut = p_rut);
    RETURN;
END;
$$ LANGUAGE plpgsql;
-- PRUEBA: SELECT * FROM fn_devoluciones_cliente() LIMIT 10;

-- 6.2 Productos con ofertas vigentes: precio original vs actual
CREATE OR REPLACE FUNCTION fn_productos_con_oferta()
RETURNS TABLE(producto VARCHAR, precio_original DECIMAL, descuento DECIMAL, precio_final DECIMAL) AS $$
BEGIN
    RETURN QUERY
        SELECT p.nombre, p.precio, o.Porcentaje_descuento,
               ROUND(p.precio * (1 - o.Porcentaje_descuento / 100), 2)
        FROM Producto p
        JOIN Oferta o ON p.id_oferta = o.id_oferta
        WHERE o.Fecha_fin >= CURRENT_DATE;
    RETURN;
END;
$$ LANGUAGE plpgsql;
-- PRUEBA: SELECT * FROM fn_productos_con_oferta() LIMIT 10;

-- 6.3 Capital reintegrado por devoluciones/reembolsos en el año fiscal
CREATE OR REPLACE FUNCTION fn_capital_reembolsado(INT DEFAULT NULL)
RETURNS TABLE(total_reembolsado DECIMAL, cantidad_reembolsos BIGINT) AS $$
DECLARE
    p_anio ALIAS FOR $1;
    v_anio INT;
BEGIN
    v_anio := COALESCE(p_anio, EXTRACT(YEAR FROM CURRENT_DATE)::INT);
    RETURN QUERY
        SELECT SUM(r.monto_reembolsado), COUNT(r.id_reembolso)
        FROM Reembolso r
        JOIN Devolucion d ON r.id_reembolso = d.id_reembolso
        WHERE EXTRACT(YEAR FROM d.fecha_solicitud) = v_anio;
    RETURN;
END;
$$ LANGUAGE plpgsql;
-- PRUEBA: SELECT * FROM fn_capital_reembolsado();


-- ************************************************************
-- SECCIÓN 7: VALIDACIÓN DEMOGRÁFICA (8 → 4 funciones)
-- ************************************************************

-- 7.1 Edad cronológica de clientes e identificar menores
CREATE OR REPLACE FUNCTION fn_edades_clientes()
RETURNS TABLE(rut VARCHAR, nombre VARCHAR, edad INT, es_menor BOOLEAN) AS $$
BEGIN
    RETURN QUERY
        SELECT u.Rut, u.Nombre,
               EXTRACT(YEAR FROM AGE(CURRENT_DATE, u.Fecha_nacimiento))::INT,
               CASE WHEN EXTRACT(YEAR FROM AGE(CURRENT_DATE, u.Fecha_nacimiento)) < 18 THEN TRUE ELSE FALSE END
        FROM Usuario u
        WHERE u.es_cliente = TRUE AND u.Fecha_nacimiento IS NOT NULL
        ORDER BY EXTRACT(YEAR FROM AGE(CURRENT_DATE, u.Fecha_nacimiento));
    RETURN;
END;
$$ LANGUAGE plpgsql;
-- PRUEBA: SELECT * FROM fn_edades_clientes() LIMIT 10;

-- 7.3 Segmentación etaria decenal
CREATE OR REPLACE FUNCTION fn_segmentacion_etaria()
RETURNS TABLE(rango_etario TEXT, cantidad BIGINT) AS $$
BEGIN
    RETURN QUERY
        SELECT
            (FLOOR(EXTRACT(YEAR FROM AGE(CURRENT_DATE, u.Fecha_nacimiento)) / 10) * 10)::TEXT
            || '-'
            || (FLOOR(EXTRACT(YEAR FROM AGE(CURRENT_DATE, u.Fecha_nacimiento)) / 10) * 10 + 9)::TEXT,
            COUNT(*)
        FROM Usuario u
        WHERE u.es_cliente = TRUE AND u.Fecha_nacimiento IS NOT NULL
        GROUP BY FLOOR(EXTRACT(YEAR FROM AGE(CURRENT_DATE, u.Fecha_nacimiento)) / 10)
        ORDER BY FLOOR(EXTRACT(YEAR FROM AGE(CURRENT_DATE, u.Fecha_nacimiento)) / 10);
    RETURN;
END;
$$ LANGUAGE plpgsql;
-- PRUEBA: SELECT * FROM fn_segmentacion_etaria();

-- 7.4 Correos con formato inválido (Regex)
CREATE OR REPLACE FUNCTION fn_correos_invalidos()
RETURNS TABLE(rut VARCHAR, nombre VARCHAR, correo VARCHAR) AS $$
BEGIN
    RETURN QUERY
        SELECT u.Rut, u.Nombre, u.Correo
        FROM Usuario u
        WHERE u.Correo !~ '^[A-Za-z0-9._%-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$';
    RETURN;
END;
$$ LANGUAGE plpgsql;
-- PRUEBA: SELECT * FROM fn_correos_invalidos() LIMIT 10;

-- 7.5 Emprendedores sin página web (IS NULL)
CREATE OR REPLACE FUNCTION fn_empresas_sin_web()
RETURNS TABLE(empresa VARCHAR, rut VARCHAR, nombre_dueno VARCHAR) AS $$
BEGIN
    RETURN QUERY
        SELECT e.Nombre, e.Rut, u.Nombre
        FROM Empresa e
        JOIN Usuario u ON e.Rut = u.Rut
        WHERE e.Pagina_web IS NULL;
    RETURN;
END;
$$ LANGUAGE plpgsql;
-- PRUEBA: SELECT * FROM fn_empresas_sin_web() LIMIT 10;


-- ************************************************************
-- SECCIÓN 8: VISTAS LÓGICAS E INDICADORES (10 → 3 funciones)
-- ************************************************************

-- 8.1 Factura fiscal del cliente (neto, IVA, descuento, total)
CREATE OR REPLACE FUNCTION fn_factura_cliente(VARCHAR)
RETURNS TABLE(id_compra INT, fecha DATE, neto DECIMAL, iva DECIMAL, total DECIMAL) AS $$
DECLARE
    p_rut ALIAS FOR $1;
BEGIN
    RETURN QUERY
        SELECT c.id_compra, c.fecha_compra, c.total_neto, c.total_iva, c.total_pagado
        FROM Compra c
        WHERE c.rut = p_rut
        ORDER BY c.fecha_compra DESC;
    RETURN;
END;
$$ LANGUAGE plpgsql;
-- PRUEBA: SELECT * FROM fn_factura_cliente('10000233-8') LIMIT 10;

-- 8.2 Inventario crítico (stock < 10)
CREATE OR REPLACE FUNCTION fn_inventario_critico(INT DEFAULT 10)
RETURNS TABLE(producto VARCHAR, stock INT, precio DECIMAL, categoria VARCHAR) AS $$
DECLARE
    p_umbral ALIAS FOR $1;
BEGIN
    RETURN QUERY
        SELECT p.nombre, p.stock, p.precio, c.Nombre_categoria
        FROM Producto p
        JOIN Categoria c ON p.id_categoria = c.id_categoria
        WHERE p.stock < p_umbral
        ORDER BY p.stock ASC;
    RETURN;
END;
$$ LANGUAGE plpgsql;
-- PRUEBA: SELECT * FROM fn_inventario_critico(5) LIMIT 10;

-- 8.4 Life-Time Value de cada cliente
CREATE OR REPLACE FUNCTION fn_ltv_clientes()
RETURNS TABLE(rut VARCHAR, nombre TEXT, total_transacciones BIGINT, ltv DECIMAL) AS $$
BEGIN
    RETURN QUERY
        SELECT u.Rut, (u.Nombre || ' ' || u.Apellido)::TEXT,
               COUNT(c.id_compra),
               COALESCE(SUM(c.total_pagado), 0)
        FROM Usuario u
        LEFT JOIN Compra c ON u.Rut = c.rut
        WHERE u.es_cliente = TRUE
        GROUP BY u.Rut, u.Nombre, u.Apellido
        ORDER BY COALESCE(SUM(c.total_pagado), 0) DESC;
    RETURN;
END;
$$ LANGUAGE plpgsql;
-- PRUEBA: SELECT * FROM fn_ltv_clientes() LIMIT 10;


-- ************************************************************
-- FUNCIONES CRUD (Insert, Update, Delete) POR TABLA
-- ************************************************************

-- CRUD: Usuario
CREATE OR REPLACE FUNCTION crud_insertar_usuario(VARCHAR, VARCHAR, VARCHAR, VARCHAR, VARCHAR, DATE, BOOLEAN, BOOLEAN)
RETURNS BOOLEAN AS $$
DECLARE
    p_rut ALIAS FOR $1; p_nombre ALIAS FOR $2; p_apellido ALIAS FOR $3; p_correo ALIAS FOR $4;
    p_pass ALIAS FOR $5; p_fecha ALIAS FOR $6; p_cli ALIAS FOR $7; p_emp ALIAS FOR $8;
BEGIN
    INSERT INTO Usuario (Rut, Nombre, Apellido, Correo, Contrasena, Fecha_nacimiento, es_cliente, es_emprendedor, Fecha_registro)
    VALUES (p_rut, p_nombre, p_apellido, p_correo, p_pass, p_fecha, p_cli, p_emp, CURRENT_DATE);
    RETURN TRUE;
EXCEPTION WHEN others THEN RAISE NOTICE 'Error: %', SQLERRM; RETURN FALSE;
END;
$$ LANGUAGE plpgsql;
-- PRUEBA: SELECT crud_insertar_usuario('99999999-9','Test','Crud','test.crud@mail.cl','hash123','2000-01-01',TRUE,FALSE);

CREATE OR REPLACE FUNCTION crud_actualizar_usuario(VARCHAR, VARCHAR, VARCHAR, VARCHAR)
RETURNS BOOLEAN AS $$
DECLARE
    p_rut ALIAS FOR $1; p_nombre ALIAS FOR $2; p_apellido ALIAS FOR $3; p_correo ALIAS FOR $4;
BEGIN
    UPDATE Usuario SET Nombre = p_nombre, Apellido = p_apellido, Correo = p_correo WHERE Rut = p_rut;
    IF NOT FOUND THEN RAISE EXCEPTION 'Usuario % no existe.', p_rut; END IF;
    RETURN TRUE;
EXCEPTION WHEN others THEN RAISE NOTICE 'Error: %', SQLERRM; RETURN FALSE;
END;
$$ LANGUAGE plpgsql;
-- PRUEBA: SELECT crud_actualizar_usuario('10000001-9','NuevoNombre','NuevoApellido','nuevo@correo.cl');

CREATE OR REPLACE FUNCTION crud_eliminar_usuario(VARCHAR)
RETURNS BOOLEAN AS $$
DECLARE p_rut ALIAS FOR $1;
BEGIN
    DELETE FROM Usuario WHERE Rut = p_rut;
    IF NOT FOUND THEN RAISE EXCEPTION 'Usuario % no encontrado.', p_rut; END IF;
    RETURN TRUE;
EXCEPTION WHEN others THEN RAISE NOTICE 'Error: %', SQLERRM; RETURN FALSE;
END;
$$ LANGUAGE plpgsql;
-- PRUEBA: SELECT crud_eliminar_usuario('99999999-9');

-- CRUD: Producto
CREATE OR REPLACE FUNCTION crud_insertar_producto(INT, VARCHAR, DECIMAL, VARCHAR, BOOLEAN, INT, VARCHAR, VARCHAR)
RETURNS BOOLEAN AS $$
DECLARE
    p_id ALIAS FOR $1; p_nombre ALIAS FOR $2; p_precio ALIAS FOR $3; p_desc ALIAS FOR $4;
    p_disp ALIAS FOR $5; p_stock ALIAS FOR $6; p_rut ALIAS FOR $7; p_cat ALIAS FOR $8;
BEGIN
    INSERT INTO Producto (id_producto, nombre, precio, descripcion, disponibilidad, stock, rut, id_categoria)
    VALUES (p_id, p_nombre, p_precio, p_desc, p_disp, p_stock, p_rut, p_cat);
    RETURN TRUE;
EXCEPTION WHEN others THEN RAISE NOTICE 'Error: %', SQLERRM; RETURN FALSE;
END;
$$ LANGUAGE plpgsql;
-- PRUEBA: SELECT crud_insertar_producto(9999,'Producto Test',5000,'Desc',TRUE,100,'10000001-9','C2.1.1');

CREATE OR REPLACE FUNCTION crud_actualizar_producto(INT, VARCHAR, DECIMAL, INT)
RETURNS BOOLEAN AS $$
DECLARE p_id ALIAS FOR $1; p_nombre ALIAS FOR $2; p_precio ALIAS FOR $3; p_stock ALIAS FOR $4;
BEGIN
    UPDATE Producto SET nombre = p_nombre, precio = p_precio, stock = p_stock WHERE id_producto = p_id;
    IF NOT FOUND THEN RAISE EXCEPTION 'Producto % no encontrado.', p_id; END IF;
    RETURN TRUE;
EXCEPTION WHEN others THEN RAISE NOTICE 'Error: %', SQLERRM; RETURN FALSE;
END;
$$ LANGUAGE plpgsql;
-- PRUEBA: SELECT crud_actualizar_producto(1,'Producto Editado',9999.99,50);

CREATE OR REPLACE FUNCTION crud_eliminar_producto(INT)
RETURNS BOOLEAN AS $$
DECLARE p_id ALIAS FOR $1;
BEGIN
    DELETE FROM Producto WHERE id_producto = p_id;
    IF NOT FOUND THEN RAISE EXCEPTION 'Producto % no encontrado.', p_id; END IF;
    RETURN TRUE;
EXCEPTION WHEN others THEN RAISE NOTICE 'Error: %', SQLERRM; RETURN FALSE;
END;
$$ LANGUAGE plpgsql;
-- PRUEBA: SELECT crud_eliminar_producto(9999);

-- CRUD: Servicio
CREATE OR REPLACE FUNCTION crud_insertar_servicio(INT, VARCHAR, DECIMAL, VARCHAR, BOOLEAN, VARCHAR, VARCHAR)
RETURNS BOOLEAN AS $$
DECLARE
    p_id ALIAS FOR $1; p_nombre ALIAS FOR $2; p_precio ALIAS FOR $3; p_desc ALIAS FOR $4;
    p_disp ALIAS FOR $5; p_rut ALIAS FOR $6; p_cat ALIAS FOR $7;
BEGIN
    INSERT INTO Servicio (id_servicio, nombre, precio, descripcion, disponibilidad, rut, id_categoria)
    VALUES (p_id, p_nombre, p_precio, p_desc, p_disp, p_rut, p_cat);
    RETURN TRUE;
EXCEPTION WHEN others THEN RAISE NOTICE 'Error: %', SQLERRM; RETURN FALSE;
END;
$$ LANGUAGE plpgsql;
-- PRUEBA: SELECT crud_insertar_servicio(9999,'Servicio Test',15000,'Desc',TRUE,'10000001-9','C1');

CREATE OR REPLACE FUNCTION crud_eliminar_servicio(INT)
RETURNS BOOLEAN AS $$
DECLARE p_id ALIAS FOR $1;
BEGIN
    DELETE FROM Servicio WHERE id_servicio = p_id;
    IF NOT FOUND THEN RAISE EXCEPTION 'Servicio % no encontrado.', p_id; END IF;
    RETURN TRUE;
EXCEPTION WHEN others THEN RAISE NOTICE 'Error: %', SQLERRM; RETURN FALSE;
END;
$$ LANGUAGE plpgsql;
-- PRUEBA: SELECT crud_eliminar_servicio(9999);

-- CRUD: Compra
CREATE OR REPLACE FUNCTION crud_insertar_compra(INT, DATE, VARCHAR, VARCHAR, DECIMAL, DECIMAL, DECIMAL, VARCHAR, INT)
RETURNS BOOLEAN AS $$
DECLARE
    p_id ALIAS FOR $1; p_fecha ALIAS FOR $2; p_moneda ALIAS FOR $3; p_mod ALIAS FOR $4;
    p_neto ALIAS FOR $5; p_iva ALIAS FOR $6; p_total ALIAS FOR $7; p_rut ALIAS FOR $8; p_mp ALIAS FOR $9;
BEGIN
    INSERT INTO Compra VALUES (p_id, p_fecha, p_moneda, p_mod, p_neto, p_iva, p_total, p_rut, p_mp);
    RETURN TRUE;
EXCEPTION WHEN others THEN RAISE NOTICE 'Error: %', SQLERRM; RETURN FALSE;
END;
$$ LANGUAGE plpgsql;
-- PRUEBA: SELECT crud_insertar_compra(9999,'2026-09-21','CLP','Retiro',10000,1900,11900,'10000001-9',1);

CREATE OR REPLACE FUNCTION crud_eliminar_compra(INT)
RETURNS BOOLEAN AS $$
DECLARE p_id ALIAS FOR $1;
BEGIN
    DELETE FROM Compra WHERE id_compra = p_id;
    IF NOT FOUND THEN RAISE EXCEPTION 'Compra % no encontrada.', p_id; END IF;
    RETURN TRUE;
EXCEPTION WHEN others THEN RAISE NOTICE 'Error: %', SQLERRM; RETURN FALSE;
END;
$$ LANGUAGE plpgsql;
-- PRUEBA: SELECT crud_eliminar_compra(9999);

-- CRUD: Detalle_Compra
CREATE OR REPLACE FUNCTION crud_insertar_detalle(INT, INT, DECIMAL, INT, INT, INT)
RETURNS BOOLEAN AS $$
DECLARE
    p_id ALIAS FOR $1; p_cant ALIAS FOR $2; p_precio ALIAS FOR $3;
    p_compra ALIAS FOR $4; p_prod ALIAS FOR $5; p_serv ALIAS FOR $6;
BEGIN
    INSERT INTO Detalle_Compra VALUES (p_id, p_cant, p_precio, p_compra, p_prod, p_serv);
    RETURN TRUE;
EXCEPTION WHEN others THEN RAISE NOTICE 'Error: %', SQLERRM; RETURN FALSE;
END;
$$ LANGUAGE plpgsql;
-- PRUEBA: SELECT crud_insertar_detalle(9999, 2, 5000.00, 1, 1, NULL);

CREATE OR REPLACE FUNCTION crud_eliminar_detalle(INT)
RETURNS BOOLEAN AS $$
DECLARE p_id ALIAS FOR $1;
BEGIN
    DELETE FROM Detalle_Compra WHERE id_detalle_compra = p_id;
    IF NOT FOUND THEN RAISE EXCEPTION 'Detalle % no encontrado.', p_id; END IF;
    RETURN TRUE;
EXCEPTION WHEN others THEN RAISE NOTICE 'Error: %', SQLERRM; RETURN FALSE;
END;
$$ LANGUAGE plpgsql;
-- PRUEBA: SELECT crud_eliminar_detalle(9999);

-- CRUD: Resena
CREATE OR REPLACE FUNCTION crud_insertar_resena(INT, INT, TEXT, VARCHAR, INT, INT)
RETURNS BOOLEAN AS $$
DECLARE
    p_id ALIAS FOR $1; p_punt ALIAS FOR $2; p_com ALIAS FOR $3;
    p_rut ALIAS FOR $4; p_prod ALIAS FOR $5; p_serv ALIAS FOR $6;
BEGIN
    INSERT INTO Resena (id_resena, puntaje, comentario, rut_cliente, id_producto, id_servicio)
    VALUES (p_id, p_punt, p_com, p_rut, p_prod, p_serv);
    RETURN TRUE;
EXCEPTION WHEN others THEN RAISE NOTICE 'Error: %', SQLERRM; RETURN FALSE;
END;
$$ LANGUAGE plpgsql;
-- PRUEBA: SELECT crud_insertar_resena(9999, 5, 'Excelente producto', '10000001-9', 1, NULL);

CREATE OR REPLACE FUNCTION crud_eliminar_resena(INT)
RETURNS BOOLEAN AS $$
DECLARE p_id ALIAS FOR $1;
BEGIN
    DELETE FROM Resena WHERE id_resena = p_id;
    IF NOT FOUND THEN RAISE EXCEPTION 'Resena % no encontrada.', p_id; END IF;
    RETURN TRUE;
EXCEPTION WHEN others THEN RAISE NOTICE 'Error: %', SQLERRM; RETURN FALSE;
END;
$$ LANGUAGE plpgsql;
-- PRUEBA: SELECT crud_eliminar_resena(9999);

-- CRUD: Devolucion
CREATE OR REPLACE FUNCTION crud_insertar_devolucion(INT, DATE, VARCHAR, VARCHAR, INT, VARCHAR)
RETURNS BOOLEAN AS $$
DECLARE
    p_id ALIAS FOR $1; p_fecha ALIAS FOR $2; p_motivo ALIAS FOR $3;
    p_estado ALIAS FOR $4; p_compra ALIAS FOR $5; p_rut ALIAS FOR $6;
BEGIN
    INSERT INTO Devolucion (id_devolucion, fecha_solicitud, motivo, estado_devolucion, id_compra, rut)
    VALUES (p_id, p_fecha, p_motivo, p_estado, p_compra, p_rut);
    RETURN TRUE;
EXCEPTION WHEN others THEN RAISE NOTICE 'Error: %', SQLERRM; RETURN FALSE;
END;
$$ LANGUAGE plpgsql;
-- PRUEBA: SELECT crud_insertar_devolucion(9999,'2026-09-21','Producto defectuoso','Pendiente',1,'10000001-9');

CREATE OR REPLACE FUNCTION crud_eliminar_devolucion(INT)
RETURNS BOOLEAN AS $$
DECLARE p_id ALIAS FOR $1;
BEGIN
    DELETE FROM Devolucion WHERE id_devolucion = p_id;
    IF NOT FOUND THEN RAISE EXCEPTION 'Devolucion % no encontrada.', p_id; END IF;
    RETURN TRUE;
EXCEPTION WHEN others THEN RAISE NOTICE 'Error: %', SQLERRM; RETURN FALSE;
END;
$$ LANGUAGE plpgsql;
-- PRUEBA: SELECT crud_eliminar_devolucion(9999);

-- CRUD: Wishlist
CREATE OR REPLACE FUNCTION crud_insertar_wishlist(INT, VARCHAR, INT, INT)
RETURNS BOOLEAN AS $$
DECLARE p_id ALIAS FOR $1; p_rut ALIAS FOR $2; p_prod ALIAS FOR $3; p_serv ALIAS FOR $4;
BEGIN
    INSERT INTO Wishlist (id_wishlist, rut, id_producto, id_servicio, fecha_agregada)
    VALUES (p_id, p_rut, p_prod, p_serv, CURRENT_DATE);
    RETURN TRUE;
EXCEPTION WHEN others THEN RAISE NOTICE 'Error: %', SQLERRM; RETURN FALSE;
END;
$$ LANGUAGE plpgsql;
-- PRUEBA: SELECT crud_insertar_wishlist(9999, '10000001-9', 1, NULL);

CREATE OR REPLACE FUNCTION crud_eliminar_wishlist(INT)
RETURNS BOOLEAN AS $$
DECLARE p_id ALIAS FOR $1;
BEGIN
    DELETE FROM Wishlist WHERE id_wishlist = p_id;
    IF NOT FOUND THEN RAISE EXCEPTION 'Wishlist % no encontrado.', p_id; END IF;
    RETURN TRUE;
EXCEPTION WHEN others THEN RAISE NOTICE 'Error: %', SQLERRM; RETURN FALSE;
END;
$$ LANGUAGE plpgsql;
-- PRUEBA: SELECT crud_eliminar_wishlist(9999);

-- ************************************************************
-- CURSOR EXPLÍCITO: Auditoría de Stock (FOR UPDATE + WHERE CURRENT OF)
-- ************************************************************
CREATE OR REPLACE FUNCTION Auditoria_Actualizar_Stock() RETURNS VOID AS $$
DECLARE
    cur_stock CURSOR FOR SELECT * FROM Producto WHERE stock < 10 FOR UPDATE;
    prod Producto%ROWTYPE;
BEGIN
    OPEN cur_stock;
    LOOP
        FETCH cur_stock INTO prod;
        IF NOT FOUND THEN EXIT; END IF;
        RAISE NOTICE 'Inventario critico: ID=% nombre=% stock=%', prod.id_producto, prod.nombre, prod.stock;
        UPDATE Producto SET stock = stock + 50 WHERE CURRENT OF cur_stock;
    END LOOP;
    CLOSE cur_stock;
END;
$$ LANGUAGE plpgsql;
-- PRUEBA: SELECT Auditoria_Actualizar_Stock();
