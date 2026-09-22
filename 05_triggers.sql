SET search_path TO public;

-- ************************************************************
-- TRIGGERS
-- ************************************************************
CREATE OR REPLACE FUNCTION fn_trg_descontar_stock_compra() RETURNS TRIGGER AS $$
DECLARE stock_actual Producto.stock%TYPE;
BEGIN
    IF NEW.id_producto IS NOT NULL THEN
        SELECT stock INTO stock_actual FROM Producto WHERE id_producto = NEW.id_producto;
        IF stock_actual < NEW.cantidad THEN
            RAISE EXCEPTION 'Stock insuficiente para producto %. Disponible: %, Solicitado: %', NEW.id_producto, stock_actual, NEW.cantidad;
        END IF;
        UPDATE Producto SET stock = stock - NEW.cantidad WHERE id_producto = NEW.id_producto;
        RAISE NOTICE 'Stock descontado: producto %, cantidad %', NEW.id_producto, NEW.cantidad;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;
CREATE TRIGGER trg_descontar_stock_compra AFTER INSERT ON Detalle_Compra FOR EACH ROW EXECUTE FUNCTION fn_trg_descontar_stock_compra();

CREATE OR REPLACE FUNCTION fn_trg_auto_fecha_compra() RETURNS TRIGGER AS $$
BEGIN
    IF NEW.fecha_compra IS NULL THEN NEW.fecha_compra := CURRENT_DATE; END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;
CREATE TRIGGER trg_auto_fecha_compra BEFORE INSERT ON Compra FOR EACH ROW EXECUTE FUNCTION fn_trg_auto_fecha_compra();

CREATE OR REPLACE FUNCTION fn_trg_validar_correo() RETURNS TRIGGER AS $$
BEGIN
    IF NEW.Correo !~ '^[A-Za-z0-9._%-]+@[A-Za-z0-9.-]+[.][A-Za-z]+$' THEN
        RAISE EXCEPTION 'Formato de correo invalido: %', NEW.Correo;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;
CREATE TRIGGER trg_validar_correo BEFORE INSERT OR UPDATE ON Usuario FOR EACH ROW EXECUTE FUNCTION fn_trg_validar_correo();

CREATE OR REPLACE FUNCTION fn_trg_validar_rut() RETURNS TRIGGER AS $$
DECLARE
    rut_cuerpo INT; rut_dv CHAR(1); suma INT := 0; multiplo INT := 2; resto INT; dv_calculado CHAR(1);
BEGIN
    rut_cuerpo := CAST(SPLIT_PART(NEW.Rut, '-', 1) AS INT);
    rut_dv := UPPER(SPLIT_PART(NEW.Rut, '-', 2));
    WHILE rut_cuerpo > 0 LOOP
        suma := suma + (rut_cuerpo % 10) * multiplo;
        rut_cuerpo := TRUNC(rut_cuerpo / 10);
        multiplo := multiplo + 1;
        IF multiplo = 8 THEN multiplo := 2; END IF;
    END LOOP;
    resto := 11 - (suma % 11);
    IF resto = 11 THEN dv_calculado := '0';
    ELSIF resto = 10 THEN dv_calculado := 'K';
    ELSE dv_calculado := CAST(resto AS CHAR); END IF;
    IF rut_dv <> dv_calculado THEN
        RAISE NOTICE 'DV incorrecto (%). Corregido a (%).', rut_dv, dv_calculado;
        NEW.Rut := SPLIT_PART(NEW.Rut, '-', 1) || '-' || dv_calculado;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;
CREATE TRIGGER trg_validar_rut BEFORE INSERT OR UPDATE ON Usuario FOR EACH ROW EXECUTE FUNCTION fn_trg_validar_rut();

CREATE OR REPLACE FUNCTION fn_trg_consistencia_factura() RETURNS TRIGGER AS $$
BEGIN
    IF NEW.total_pagado <> (NEW.total_neto + NEW.total_iva) THEN
        RAISE NOTICE 'Inconsistencia. Recalculando: neto=% + iva=%', NEW.total_neto, NEW.total_iva;
        NEW.total_pagado := NEW.total_neto + NEW.total_iva;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;
CREATE TRIGGER trg_consistencia_factura BEFORE INSERT OR UPDATE ON Compra FOR EACH ROW EXECUTE FUNCTION fn_trg_consistencia_factura();

CREATE OR REPLACE FUNCTION fn_trg_barrera_etaria() RETURNS TRIGGER AS $$
DECLARE
    edad_cliente INT; tiene_restriccion BOOLEAN := FALSE; rut_comprador Compra.rut%TYPE;
BEGIN
    IF NEW.id_servicio IS NOT NULL THEN
        SELECT (Atributos->>'restriccion_mayoria_edad')::boolean INTO tiene_restriccion
        FROM Servicio WHERE id_servicio = NEW.id_servicio;
        IF tiene_restriccion = TRUE THEN
            SELECT rut INTO rut_comprador FROM Compra WHERE id_compra = NEW.id_compra;
            SELECT extract(year from age(CURRENT_DATE, Fecha_nacimiento)) INTO edad_cliente
            FROM Usuario WHERE Rut = rut_comprador;
            IF edad_cliente < 18 THEN
                RAISE EXCEPTION 'Cliente no cumple edad minima (18) para este servicio.';
            END IF;
        END IF;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;
CREATE TRIGGER trg_barrera_etaria BEFORE INSERT ON Detalle_Compra FOR EACH ROW EXECUTE FUNCTION fn_trg_barrera_etaria();
