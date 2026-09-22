import random
import json
from datetime import datetime, timedelta

def generate_inserts():
    with open("02_inserts.sql", "w", encoding="utf-8") as f:
        f.write("SET search_path TO public;\n\n")
        f.write("-- SCRIPT GENERADOR MASIVO DE DATOS (BD2)\n")
        
        # 1. CATEGORIAS (Basado en la jerarquía del enunciado)
        f.write("-- CATEGORIAS (Jerarquía Oficial del Enunciado)\n")
        f.write("INSERT INTO Categoria (id_categoria, Nombre_categoria, Descripcion, id_categoria_padre) VALUES\n")
        cats = [
            ("C1", "Servicios", "Servicios", "NULL"),
            ("C1.1", "Computación y Tecnología", "TI", "'C1'"),
            ("C1.2", "Servicios domésticos", "Domésticos", "'C1'"),
            ("C1.2.1", "Aseo", "Limpieza", "'C1.2'"),
            ("C1.2.2", "Trabajo de jardín", "Jardín", "'C1.2'"),
            ("C1.2.3", "Limpieza de combustión y reparaciones", "Reparaciones", "'C1.2'"),
            ("C1.2.4", "Cuidado de adultos", "Enfermería", "'C1.2'"),
            ("C1.2.5", "Cuidado de niños", "Niños", "'C1.2'"),
            ("C1.3", "Servicios profesionales", "Profesionales", "'C1'"),
            ("C1.3.1", "Computación", "IT", "'C1.3'"),
            ("C1.3.2", "Abogados", "Leyes", "'C1.3'"),
            ("C1.3.3", "Contadores", "Finanzas", "'C1.3'"),
            ("C1.3.6", "Servicio de salud", "Salud", "'C1.3'"),
            ("C1.3.6.1", "Médico", "Consulta", "'C1.3.6'"),
            ("C1.3.7", "Servicios educativos", "Educación", "'C1.3'"),
            ("C1.4", "Vehículos", "Mecánica", "'C1'"),
            ("C1.5", "Confección de ropa", "Ropa", "'C1'"),
            ("C2", "Productos", "Bienes", "NULL"),
            ("C2.1", "Tecnología", "Electrónica", "'C2'"),
            ("C2.1.1", "Computación", "PCs", "'C2.1'"),
            ("C2.1.2", "Audio y Música", "Equipos", "'C2.1'"),
            ("C2.1.3", "Juegos y consolas", "Gaming", "'C2.1'"),
            ("C2.2", "Celulares", "Smartphones", "'C2'"),
            ("C2.3", "Hogar y Cocina", "Hogar", "'C2'"),
            ("C2.4", "Alimentación", "Comida", "'C2'"),
            ("C2.7", "Ropa, moda y calzado", "Moda", "'C2'")
        ]
        cat_values = [f"('{c[0]}', '{c[1]}', '{c[2]}', {c[3]})" for c in cats]
        f.write(",\n".join(cat_values) + ";\n\n")

        # 2. USUARIOS (1000)
        f.write("-- USUARIOS\n")
        f.write("INSERT INTO Usuario (Rut, Nombre, Apellido, Correo, Contrasena, Fecha_nacimiento, es_cliente, es_emprendedor, Fecha_registro, Calificacion_promedio) VALUES\n")
        usuarios = []
        ruts = []
        nombres = ["Juan", "Maria", "Pedro", "Ana", "Luis", "Carlos", "Sofia", "Diego", "Valentina", "Camila", "Javier", "Isabella"]
        apellidos = ["Perez", "Gonzalez", "Rojas", "Soto", "Silva", "Contreras", "Morales", "Sepulveda", "Munoz", "Tapia"]
        for i in range(1, 1001):
            rut = f"{10000000+i}-{random.randint(0,9)}"
            ruts.append(rut)
            nombre = random.choice(nombres)
            apellido = random.choice(apellidos)
            correo = f"{nombre.lower()}.{apellido.lower()}{i}@correo.cl"
            fecha_nac = f"'{random.randint(1960, 2005)}-0{random.randint(1,9)}-1{random.randint(0,9)}'"
            usuarios.append(f"('{rut}', '{nombre}', '{apellido}', '{correo}', 'hash123', {fecha_nac}, TRUE, TRUE, '2025-01-01', {round(random.uniform(1.0, 5.0), 2)})")
        
        for i in range(0, 1000, 500):
            chunk = usuarios[i:i+500]
            if chunk:
                f.write(",\n".join(chunk) + ";\n")
                if i < 500: f.write("INSERT INTO Usuario (Rut, Nombre, Apellido, Correo, Contrasena, Fecha_nacimiento, es_cliente, es_emprendedor, Fecha_registro, Calificacion_promedio) VALUES\n")
        f.write("\n")

        # 3. OFERTAS
        f.write("-- OFERTAS\n")
        f.write("INSERT INTO Oferta (id_oferta, Porcentaje_descuento, Fecha_inicio, Fecha_fin) VALUES\n")
        ofertas = []
        for i in range(1, 1001):
            ofertas.append(f"({i}, {random.uniform(5.0, 50.0):.2f}, '2025-01-01', '2026-12-31')")
        f.write(",\n".join(ofertas) + ";\n\n")

        # 4. PRODUCTOS
        f.write("-- PRODUCTOS (Coherentes con las Categorías)\n")
        f.write("INSERT INTO Producto (id_producto, nombre, precio, descripcion, disponibilidad, stock, Atributos, rut, id_categoria) VALUES\n")
        productos = []
        
        cat_prod = ["C2.1.1", "C2.1.2", "C2.1.3", "C2.2", "C2.3", "C2.4", "C2.7"]
        mapping_prod = {
            "C2.1.1": (["Laptop", "Notebook", "Teclado", "Mouse"], ["Gamer", "Oficina", "Profesional"]),
            "C2.1.2": (["Audifonos", "Parlante", "Microfono"], ["Bluetooth", "Inalambrico", "Pro"]),
            "C2.1.3": (["Consola", "Videojuego", "Mando"], ["Retro", "NextGen", "Portatil"]),
            "C2.2": (["Smartphone", "Celular", "Funda"], ["Pro", "Lite", "Anti-golpes"]),
            "C2.3": (["Licuadora", "Microondas", "Sarten"], ["Industrial", "Hogar", "Acero Inoxidable"]),
            "C2.4": (["Arroz", "Fideos", "Aceite", "Galletas"], ["Organico", "Integral", "Premium"]),
            "C2.7": (["Polera", "Pantalon", "Zapatillas", "Chaqueta"], ["Deportiva", "Casual", "Formal"])
        }

        for i in range(1, 1001):
            precio = random.randint(10, 500) * 100
            stock = random.randint(10, 100)
            id_cat = random.choice(cat_prod)
            sust, adj = mapping_prod[id_cat]
            nombre_prod = f"{random.choice(sust)} {random.choice(adj)} {i}"
            
            if id_cat == "C2.7":
                attr = json.dumps({"talla": random.choice(["S","M","L","XL"]), "color": random.choice(["Rojo","Azul","Negro"])}, ensure_ascii=False)
            else:
                attr = json.dumps({"marca": "TestMarca", "garantia": f"{random.randint(3,12)} meses"}, ensure_ascii=False)
                
            rut = random.choice(ruts)
            productos.append(f"({i}, '{nombre_prod}', {precio}, 'Descripción de {nombre_prod}', TRUE, {stock}, '{attr}', '{rut}', '{id_cat}')")
        
        for i in range(0, 1000, 500):
            chunk = productos[i:i+500]
            if chunk:
                f.write(",\n".join(chunk) + ";\n")
                if i < 500: f.write("INSERT INTO Producto (id_producto, nombre, precio, descripcion, disponibilidad, stock, Atributos, rut, id_categoria) VALUES\n")
        f.write("\n")

        # 5. SERVICIOS
        f.write("-- SERVICIOS (Coherentes con las Categorías)\n")
        f.write("INSERT INTO Servicio (id_servicio, nombre, precio, descripcion, disponibilidad, Atributos, rut, id_categoria) VALUES\n")
        servicios = []
        
        cat_serv = ["C1.1", "C1.2.1", "C1.2.2", "C1.3.1", "C1.3.2", "C1.3.3", "C1.3.6.1", "C1.3.7", "C1.4"]
        mapping_serv = {
            "C1.1": (["Instalacion Windows", "Mantenimiento PC", "Armado de Servidor"], ["Remoto", "Presencial"]),
            "C1.2.1": (["Aseo Profundo", "Limpieza de Alfombras", "Sanitizacion"], ["Domicilio"]),
            "C1.2.2": (["Poda de Arboles", "Mantenimiento Jardin", "Corte de Pasto"], ["Domicilio"]),
            "C1.3.1": (["Desarrollo Web", "Asesoria SEO", "Diseño de Logo"], ["Remoto", "Presencial"]),
            "C1.3.2": (["Asesoria Legal", "Redaccion Contrato", "Representacion"], ["Remoto", "Oficina"]),
            "C1.3.3": (["Declaracion Impuestos", "Auditoria Contable"], ["Remoto"]),
            "C1.3.6.1": (["Consulta General", "Chequeo Medico"], ["Presencial", "Telemedicina"]),
            "C1.3.7": (["Clases Matematicas", "Tutorias Ingles", "Curso Programacion"], ["Online", "Presencial"]),
            "C1.4": (["Cambio de Aceite", "Pintura Auto", "Scanner Automotriz"], ["Taller", "Domicilio"])
        }

        for i in range(1, 1001):
            precio = random.randint(50, 200) * 1000
            id_cat = random.choice(cat_serv)
            sust_list, adj_list = mapping_serv[id_cat]
            nombre_serv = f"{random.choice(sust_list)} {random.choice(adj_list)}"
            
            modalidad = random.choice(["Remoto", "Presencial"])
            attr = json.dumps({"Modalidad": modalidad}, ensure_ascii=False)
            rut = random.choice(ruts)
            servicios.append(f"({i}, '{nombre_serv}', {precio}, 'Descripción de {nombre_serv}', TRUE, '{attr}', '{rut}', '{id_cat}')")
        
        for i in range(0, 1000, 500):
            chunk = servicios[i:i+500]
            if chunk:
                f.write(",\n".join(chunk) + ";\n")
                if i < 500: f.write("INSERT INTO Servicio (id_servicio, nombre, precio, descripcion, disponibilidad, Atributos, rut, id_categoria) VALUES\n")
        f.write("\n")

        # 5.5 TRANSACCION
        f.write("-- TRANSACCION\n")
        f.write("INSERT INTO Transaccion (Referencia_transaccion, Estado_pago) VALUES\n")
        transacciones = []
        for i in range(1, 1001):
            transacciones.append(f"('REF-{i}', 'Aprobado')")
        for i in range(0, 1000, 500):
            chunk = transacciones[i:i+500]
            if chunk:
                f.write(",\n".join(chunk) + ";\n")
                if i < 500: f.write("INSERT INTO Transaccion (Referencia_transaccion, Estado_pago) VALUES\n")
        f.write("\n")

        # 6. MEDIO_PAGO
        f.write("-- MEDIO PAGO\n")
        f.write("INSERT INTO Medio_pago (id_medio_pago, tipo_pago, ultimos_4_digitos, fecha, referencia_transaccion) VALUES\n")
        pagos = []
        for i in range(1, 1001):
            tipo = random.choice(['Debito', 'Credito', 'Transferencia'])
            pagos.append(f"({i}, '{tipo}', '{random.randint(1000,9999)}', '2025-06-01', 'REF-{i}')")
        f.write(",\n".join(pagos) + ";\n\n")

        # 7. COMPRA
        f.write("-- COMPRA\n")
        f.write("INSERT INTO Compra (id_compra, fecha_compra, moneda, modalidad_entrega, total_neto, total_iva, total_pagado, rut, id_medio_pago) VALUES\n")
        compras = []
        for i in range(1, 1001):
            neto = random.randint(10000, 50000)
            iva = neto * 0.19
            total = neto + iva
            rut = random.choice(ruts)
            modalidad = random.choice(["Despacho", "Retiro"])
            compras.append(f"({i}, '2025-06-01', 'CLP', '{modalidad}', {neto}, {iva}, {total}, '{rut}', {i})")
        
        for i in range(0, 1000, 500):
            chunk = compras[i:i+500]
            if chunk:
                f.write(",\n".join(chunk) + ";\n")
                if i < 500: f.write("INSERT INTO Compra (id_compra, fecha_compra, moneda, modalidad_entrega, total_neto, total_iva, total_pagado, rut, id_medio_pago) VALUES\n")
        f.write("\n")

        # 8. DETALLE_COMPRA
        f.write("-- DETALLE COMPRA\n")
        f.write("INSERT INTO Detalle_Compra (id_detalle_compra, cantidad, precio_vendido, id_compra, id_producto) VALUES\n")
        det_compras = []
        for i in range(1, 1001):
            det_compras.append(f"({i}, {random.randint(1,5)}, {random.randint(1000,5000)}, {i}, {random.randint(1,1000)})")
        
        for i in range(0, 1000, 500):
            chunk = det_compras[i:i+500]
            if chunk:
                f.write(",\n".join(chunk) + ";\n")
                if i < 500: f.write("INSERT INTO Detalle_Compra (id_detalle_compra, cantidad, precio_vendido, id_compra, id_producto) VALUES\n")
        f.write("\n")

        # 8.5 DIRECCION (Requerida por envío)
        f.write("-- DIRECCION\n")
        f.write("INSERT INTO Direccion (id_direccion, calle, numero, tipo, rut, id_comuna) VALUES\n")
        direcciones = []
        for i in range(1, 1001):
            rut = random.choice(ruts)
            direcciones.append(f"({i}, 'Calle {i}', '{random.randint(100, 9000)}', 'Casa', '{rut}', 11302)") # 11302 es una comuna real del script Chile
        for i in range(0, 1000, 500):
            chunk = direcciones[i:i+500]
            if chunk:
                f.write(",\n".join(chunk) + ";\n")
                if i < 500: f.write("INSERT INTO Direccion (id_direccion, calle, numero, tipo, rut, id_comuna) VALUES\n")
        f.write("\n")

        # 8.6 SEGUIMIENTO
        f.write("-- SEGUIMIENTO\n")
        f.write("INSERT INTO Seguimiento (Codigo_seguimiento, Empresa_transporte) VALUES\n")
        seguimientos = []
        for i in range(1, 1001):
            seguimientos.append(f"('TRK-{i}', 'Chilexpress')")
        for i in range(0, 1000, 500):
            chunk = seguimientos[i:i+500]
            if chunk:
                f.write(",\n".join(chunk) + ";\n")
                if i < 500: f.write("INSERT INTO Seguimiento (Codigo_seguimiento, Empresa_transporte) VALUES\n")
        f.write("\n")

        # 9. ENVIO
        f.write("-- ENVIO\n")
        f.write("INSERT INTO Envio (id_envio, id_direccion, fecha_envio, fecha_entrega_estimada, estado_envio, codigo_seguimiento, id_compra) VALUES\n")
        envios = []
        for i in range(1, 1001):
            envios.append(f"('ENV-{i}', {i}, '2025-06-02', '2025-06-05', 'Enviado', 'TRK-{i}', {i})")
        
        for i in range(0, 1000, 500):
            chunk = envios[i:i+500]
            if chunk:
                f.write(",\n".join(chunk) + ";\n")
                if i < 500: f.write("INSERT INTO Envio (id_envio, id_direccion, fecha_envio, fecha_entrega_estimada, estado_envio, codigo_seguimiento, id_compra) VALUES\n")
        f.write("\n")

        # 10. RESENA
        f.write("-- RESENA\n")
        f.write("INSERT INTO Resena (id_resena, puntaje, comentario, rut_cliente, id_producto) VALUES\n")
        resenas = []
        for i in range(1, 1001):
            rut = random.choice(ruts)
            resenas.append(f"({i}, {random.randint(1,5)}, 'Comentario {i}', '{rut}', {random.randint(1,1000)})")
        
        for i in range(0, 1000, 500):
            chunk = resenas[i:i+500]
            if chunk:
                f.write(",\n".join(chunk) + ";\n")
                if i < 500: f.write("INSERT INTO Resena (id_resena, puntaje, comentario, rut_cliente, id_producto) VALUES\n")
        f.write("\n")

        # 11. PREGUNTA
        f.write("-- PREGUNTA\n")
        f.write("INSERT INTO Pregunta (id_pregunta, Texto_pregunta, Texto_respuesta, Fecha_pregunta, Fecha_respuesta) VALUES\n")
        preguntas = []
        for i in range(1, 1001):
            estado = random.choice(["Respondida", "Pendiente"])
            resp = "'Sí, tenemos stock disponible.'" if estado == "Respondida" else "NULL"
            fecha_resp = "'2025-05-16'" if estado == "Respondida" else "NULL"
            preguntas.append(f"('PRG-{i}', '¿Tienen más colores de este producto {i}?', {resp}, '2025-05-15', {fecha_resp})")
        
        for i in range(0, 1000, 500):
            chunk = preguntas[i:i+500]
            if chunk:
                f.write(",\n".join(chunk) + ";\n")
                if i < 500: f.write("INSERT INTO Pregunta (id_pregunta, Texto_pregunta, Texto_respuesta, Fecha_pregunta, Fecha_respuesta) VALUES\n")
        f.write("\n")

        # 12. TRATA_PREGUNTA_PRODUCTO
        f.write("-- TRATA_PREGUNTA_PRODUCTO\n")
        f.write("INSERT INTO Trata_Pregunta_Producto (id_pregunta, id_producto) VALUES\n")
        trata_pp = []
        for i in range(1, 1001):
            trata_pp.append(f"('PRG-{i}', {random.randint(1,1000)})")
        
        for i in range(0, 1000, 500):
            chunk = trata_pp[i:i+500]
            if chunk:
                f.write(",\n".join(chunk) + ";\n")
                if i < 500: f.write("INSERT INTO Trata_Pregunta_Producto (id_pregunta, id_producto) VALUES\n")
        f.write("\n")

        print("Generación masiva y coherente (todas las tablas) completada.")

if __name__ == '__main__':
    generate_inserts()
