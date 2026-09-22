# Proyecto BD2 — Plataforma Compra-Venta

## 1. Levantar el Entorno
```bash
docker-compose up -d
```

## 2. Entrar a PostgreSQL
```bash
docker exec -it postgres_db psql -U ICINF -d compra_venta
```

## 3. Cargar Esquema y Datos
```sql
\i /workspace/00_Chile.sql
\i /workspace/01_tablas.sql
\i /workspace/02_inserts.sql
```

## 4. Cargar Consultas y Vistas
```sql
\i /workspace/03_consultas.sql
```

## 5. Cargar Funciones y Triggers
```sql
\i /workspace/04_funciones.sql
\i /workspace/05_triggers.sql
```

## 6. Probar Funciones (Sección 1: Consolidación Temporal)
```sql
-- 1.1 Cuántos clientes han comprado un producto X en un período determinado
SELECT fn_count_clientes_producto('Laptop', '2025-01-01', '2026-12-31');
-- 1.2 Clientes que han comprado un determinado producto X en un período
SELECT * FROM fn_clientes_producto('Laptop', '2025-01-01', '2026-12-31') LIMIT 10;
-- 1.3 Cuántos clientes han comprado un servicio X en un período determinado
SELECT fn_count_clientes_servicio('Mantenimiento', '2025-01-01', '2026-12-31');
-- 1.4 Clientes que han comprado un determinado servicio X en un período
SELECT * FROM fn_clientes_servicio('Instalacion', '2025-01-01', '2026-12-31') LIMIT 10;
-- 1.5 Total de compras y pagado del mes actual por cliente X (aplica descuento si > 5)
SELECT * FROM fn_resumen_mes_cliente('10000233-8');
-- 1.6 Total de ventas del mes por artículo y por vendedor, totalizando al vendedor
SELECT * FROM fn_ventas_mes_vendedor('10000233-8') LIMIT 10;
-- 1.7 Volumen de ventas generadas fines de semana frente a días hábiles
SELECT * FROM fn_ventas_finde_vs_semana();
-- 1.8 Variación porcentual de ingresos entre mes en curso y mes anterior
SELECT * FROM fn_variacion_mensual();
-- 1.9 Ventas del último trimestre que incluyeron aplicación de descuento
SELECT * FROM fn_ventas_con_descuento() LIMIT 10;
```

## 7. Probar Funciones (Sección 2: Georreferenciación)
```sql
-- 2.1 Listar ciudades donde se ha realizado un determinado servicio X
SELECT * FROM fn_ciudades_servicio('Mantenimiento') LIMIT 10;
-- 2.2 Listar ciudades donde se ha enviado un determinado producto X
SELECT * FROM fn_ciudades_producto_enviado('Laptop') LIMIT 10;
-- 2.3 Productos por cada vendedor que tienen despacho pendiente
SELECT * FROM fn_despacho_pendiente() LIMIT 10;
-- 2.4 Tiempo promedio de tránsito logístico por empresa de transporte
SELECT * FROM fn_tiempo_transito();
-- 2.6 Despachos procesados con número de seguimiento logístico nulo
SELECT * FROM fn_envios_sin_seguimiento() LIMIT 10;
```

## 8. Probar Funciones (Sección 3: Fidelización)
```sql
-- 3.1 Producto que más se vende por cada vendedor
SELECT * FROM fn_producto_top_vendedor() LIMIT 10;
-- 3.3 Cantidad de consultas sin responder de un producto
SELECT * FROM fn_preguntas_sin_responder() LIMIT 10;
-- 3.4 Productos de un vendedor X con calificación de 4 o más
SELECT * FROM fn_productos_bien_calificados('10000233-8') LIMIT 10;
-- 3.5 Emprendedores que posean calificaciones promedio menores a 3
SELECT * FROM fn_emprendedores_baja_calificacion() LIMIT 10;
-- 3.7 Reseñas textuales que contengan palabras clave como 'excelente'
SELECT * FROM fn_resenas_keyword('excelente') LIMIT 10;
-- 3.8 Clientes que han emitido más de N calificaciones en la plataforma
SELECT * FROM fn_clientes_mas_resenas(3) LIMIT 10;
-- 3.9 Tiempo de respuesta promedio de emprendedor en contestar preguntas
SELECT * FROM fn_tiempo_respuesta_preguntas() LIMIT 10;
```

## 9. Probar Funciones (Sección 4: JSON)
```sql
-- 4.1 Extraer 'Material principal' desde JSON para productos de vestuario
SELECT * FROM fn_json_material_vestuario() LIMIT 10;
-- 4.2 Filtrar servicios profesionales con restricción explícita 'Modalidad: Remoto' en JSON
SELECT * FROM fn_json_servicios_modalidad('Remoto') LIMIT 10;
-- 4.4 Productos tecnológicos que carezcan de 'Garantía' en JSON
SELECT * FROM fn_json_sin_garantia() LIMIT 10;
-- 4.5 Vista desnormalizada de color y tamaño alojadas en el JSON
SELECT * FROM fn_json_variantes_producto() LIMIT 10;
```

## 10. Probar Funciones (Sección 5: Exclusión y Conjuntos)
```sql
-- 5.1 Servicios que no se han contratado en el mes X
SELECT * FROM fn_servicios_no_contratados(6) LIMIT 10;
-- 5.3 Clientes a los que un vendedor X ha realizado un negocio
SELECT * FROM fn_clientes_de_vendedor('10000233-8') LIMIT 10;
-- 5.4 Usuarios con rol dual (clientes y emprendedores simultáneamente)
SELECT * FROM fn_usuarios_dual() LIMIT 10;
-- 5.5 Clientes activos con wishlist pero sin concretar compras (NOT IN)
SELECT * FROM fn_wishlist_sin_compras() LIMIT 10;
-- 5.9 Productos frecuentemente adquiridos de manera conjunta
SELECT * FROM fn_productos_comprados_juntos() LIMIT 10;
```

## 11. Probar Funciones (Sección 6: Inventario y Retornos)
```sql
-- 6.1 Productos que han tenido devoluciones por cliente y su motivo
SELECT * FROM fn_devoluciones_cliente() LIMIT 10;
-- 6.2 Productos con ofertas vigentes (precio original vs actual)
SELECT * FROM fn_productos_con_oferta() LIMIT 10;
-- 6.3 Volumen total de capital reintegrado por devoluciones/reembolsos
SELECT * FROM fn_capital_reembolsado();
```

## 12. Probar Funciones (Sección 7: Validación Demográfica)
```sql
-- 7.1 Edad cronológica de cada cliente e identificar menores de edad
SELECT * FROM fn_edades_clientes() LIMIT 10;
-- 7.3 Segmentar base de clientes en grupos etarios decenales
SELECT * FROM fn_segmentacion_etaria();
-- 7.4 Correos con anomalías estructurales (Regex)
SELECT * FROM fn_correos_invalidos() LIMIT 10;
-- 7.5 Emprendedores cuya empresa carezca de página web
SELECT * FROM fn_empresas_sin_web() LIMIT 10;
```

## 13. Probar Funciones (Sección 8: Vistas e Indicadores)
```sql
-- 8.1 Vista integral de factura fiscal (neto, IVA, descuentos)
SELECT * FROM fn_factura_cliente('10000233-8') LIMIT 10;
-- 8.2 Inventario crítico (stock operativo descienda de N unidades)
SELECT * FROM fn_inventario_critico(5) LIMIT 10;
-- 8.4 Valor histórico consolidado (Life-Time Value) de cada cliente
SELECT * FROM fn_ltv_clientes() LIMIT 10;
```

## 14. Probar CRUD
```sql
SELECT crud_insertar_usuario('99999999-9','Test','Crud','test.crud@mail.cl','hash123','2000-01-01',TRUE,FALSE);
SELECT crud_actualizar_usuario('99999999-9','Editado','Apellido','edit@mail.cl');
SELECT crud_eliminar_usuario('99999999-9');

SELECT crud_insertar_producto(9999,'Producto Test',5000,'Desc',TRUE,100,'10000001-9','C2.1.1');
SELECT crud_actualizar_producto(9999,'Editado',9999.99,50);
SELECT crud_eliminar_producto(9999);
```

## 15. Probar Triggers
```sql
-- Correo inválido (debe fallar)
SELECT crud_insertar_usuario('88888888-8','Test','Trg','correo-invalido','hash','2000-01-01',TRUE,FALSE);

-- Cursor FOR UPDATE + WHERE CURRENT OF
SELECT Auditoria_Actualizar_Stock();
```

## 16. Limpiar y Reiniciar la Base de Datos
```sql
DROP SCHEMA public CASCADE;
CREATE SCHEMA public;
GRANT ALL ON SCHEMA public TO public;
```

---

## Estructura de Archivos
| Archivo | Descripción |
|---------|-------------|
| `00_Chile.sql` | Regiones, Provincias y Comunas |
| `01_tablas.sql` | Esquema relacional (24 tablas + CHECK + FK) |
| `02_inserts.sql` | Datos masivos (1000+ por tabla) |
| `03_consultas.sql` | 20 Consultas y Vistas |
| `04_funciones.sql` | 40 Funciones + 18 CRUD + Cursor |
| `05_triggers.sql` | 6 Triggers |
