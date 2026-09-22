SET search_path TO public;
-- ============================================================
-- TABLAS SIN DEPENDENCIAS
-- ============================================================

CREATE TABLE Oferta (
    id_oferta            INT          PRIMARY KEY,
    Porcentaje_descuento DECIMAL(5,2) NOT NULL,
    Fecha_inicio         DATE         NOT NULL,
    Fecha_fin            DATE         NOT NULL,
    CONSTRAINT chk_oferta_porcentaje CHECK (Porcentaje_descuento > 0 AND Porcentaje_descuento <= 100),
    CONSTRAINT chk_oferta_fecha_ini  CHECK (Fecha_inicio >= '1995-01-01'),
    CONSTRAINT chk_oferta_fechas     CHECK (Fecha_fin > Fecha_inicio)
);

CREATE TABLE Pregunta (
    id_pregunta     VARCHAR(20)  PRIMARY KEY,
    Texto_pregunta  VARCHAR(300) NOT NULL,
    Texto_respuesta VARCHAR(300),
    Fecha_pregunta  DATE         NOT NULL,
    Fecha_respuesta DATE,
    Estado          VARCHAR(20)  NOT NULL,
    CONSTRAINT chk_pregunta_fechas CHECK (Fecha_respuesta IS NULL OR Fecha_respuesta > Fecha_pregunta),
    CONSTRAINT chk_pregunta_estado CHECK (Estado IN ('Pendiente','Respondida'))
);

CREATE TABLE Categoria (
    id_categoria     VARCHAR(20)  PRIMARY KEY,
    Nombre_categoria VARCHAR(50)  NOT NULL,
    Descripcion      VARCHAR(100),
    id_categoria_padre VARCHAR(20),
    FOREIGN KEY (id_categoria_padre) REFERENCES Categoria(id_categoria)
);

CREATE TABLE Transaccion (
    Referencia_transaccion VARCHAR(50) PRIMARY KEY,
    Estado_pago            VARCHAR(20) NOT NULL
);

CREATE TABLE Seguimiento (
    Codigo_seguimiento VARCHAR(30) PRIMARY KEY,
    Empresa_transporte VARCHAR(30) NOT NULL
);

-- ============================================================
-- USUARIO Y ROLES UNIFICADOS
-- ============================================================

CREATE TABLE Usuario (
    Rut                   VARCHAR(15)  PRIMARY KEY,
    Nombre                VARCHAR(50)  NOT NULL,
    Apellido              VARCHAR(50)  NOT NULL,
    Correo                VARCHAR(100) NOT NULL UNIQUE,
    Contrasena            VARCHAR(60)  NOT NULL,
    Fecha_nacimiento      DATE,
    es_cliente            BOOLEAN      DEFAULT FALSE,
    es_emprendedor        BOOLEAN      DEFAULT FALSE,
    Fecha_registro        DATE,
    Especialidad          VARCHAR(50),
    Experiencia           VARCHAR(30),
    Calificacion_promedio DECIMAL(3,2),
    Descripcion_perfil    VARCHAR(100),
    CONSTRAINT chk_usuario_fecha CHECK (Fecha_nacimiento IS NULL OR Fecha_nacimiento >= '1940-01-01'),
    CONSTRAINT chk_emp_calificacion CHECK (Calificacion_promedio IS NULL OR (Calificacion_promedio >= 0 AND Calificacion_promedio <= 5))
);

CREATE TABLE Telefono (
    id_telefono INT         PRIMARY KEY,
    numero      VARCHAR(15) NOT NULL,
    tipo        VARCHAR(20),
    rut         VARCHAR(15) NOT NULL,
    CONSTRAINT chk_tel_numero CHECK (CHAR_LENGTH(numero) >= 8),
    FOREIGN KEY (rut) REFERENCES Usuario(Rut)
);

CREATE TABLE Direccion (
    id_direccion INT          PRIMARY KEY,
    calle        VARCHAR(100) NOT NULL,
    numero       VARCHAR(10),
    tipo         VARCHAR(20),
    rut          VARCHAR(15)  NOT NULL,
    id_comuna    INT          NOT NULL,
    FOREIGN KEY (rut)       REFERENCES Usuario(Rut),
    FOREIGN KEY (id_comuna) REFERENCES Comuna(ID)
);

CREATE TABLE Empresa (
    id_empresa VARCHAR(50) PRIMARY KEY,
    Nombre     VARCHAR(100) NOT NULL,
    Pagina_web VARCHAR(100),
    Rut        VARCHAR(15) NOT NULL,
    FOREIGN KEY (Rut) REFERENCES Usuario(Rut)
);

CREATE TABLE Mensaje (
    id_mensaje  INT          PRIMARY KEY,
    Contenido   VARCHAR(500),
    Fecha_envio DATE,
    Tipo        VARCHAR(15),
    Leido       BOOLEAN,
    Rut_remitente VARCHAR(15) NOT NULL,
    Rut_receptor  VARCHAR(15) NOT NULL,
    FOREIGN KEY (Rut_remitente) REFERENCES Usuario(Rut),
    FOREIGN KEY (Rut_receptor) REFERENCES Usuario(Rut)
);

-- ============================================================
-- PRODUCTOS, SERVICIOS Y JSON
-- ============================================================

CREATE TABLE Servicio (
    id_servicio    INT           PRIMARY KEY,
    nombre         VARCHAR(100)  NOT NULL,
    precio         DECIMAL(10,2) NOT NULL,
    descripcion    VARCHAR(200)  NOT NULL,
    disponibilidad BOOLEAN       NOT NULL,
    Atributos      JSON,
    rut            VARCHAR(15)   NOT NULL,
    id_oferta      INT,
    id_categoria   VARCHAR(20)   NOT NULL,
    CONSTRAINT chk_servicio_precio CHECK (precio > 0),
    FOREIGN KEY (rut)               REFERENCES Usuario(Rut),
    FOREIGN KEY (id_oferta)         REFERENCES Oferta(id_oferta),
    FOREIGN KEY (id_categoria)      REFERENCES Categoria(id_categoria)
);

CREATE TABLE Producto (
    id_producto    INT           PRIMARY KEY,
    nombre         VARCHAR(100)  NOT NULL,
    precio         DECIMAL(10,2) NOT NULL,
    descripcion    VARCHAR(200)  NOT NULL,
    disponibilidad BOOLEAN       NOT NULL,
    stock          INT           NOT NULL,
    Atributos      JSON,
    rut            VARCHAR(15)   NOT NULL,
    id_oferta      INT,
    id_categoria   VARCHAR(20)   NOT NULL,
    CONSTRAINT chk_producto_precio CHECK (precio > 0),
    CONSTRAINT chk_producto_stock  CHECK (stock >= 0),
    FOREIGN KEY (rut)               REFERENCES Usuario(Rut),
    FOREIGN KEY (id_oferta)         REFERENCES Oferta(id_oferta),
    FOREIGN KEY (id_categoria)      REFERENCES Categoria(id_categoria)
);

-- ============================================================
-- COTIZACIÓN, COMPRAS Y PAGOS
-- ============================================================

CREATE TABLE Cotizacion (
    id_cotizacion     INT         PRIMARY KEY,
    Fecha_emision     DATE        NOT NULL,
    Fecha_vencimiento DATE        NOT NULL,
    Estado            VARCHAR(20) NOT NULL,
    Moneda            VARCHAR(10) NOT NULL,
    Rut               VARCHAR(15) NOT NULL,
    CONSTRAINT chk_cotizacion_fecha_emision     CHECK (Fecha_emision >= '1995-01-01'),
    CONSTRAINT chk_cotizacion_fecha_vencimiento CHECK (Fecha_vencimiento > Fecha_emision),
    CONSTRAINT chk_cotizacion_estado            CHECK (Estado IN ('Solicitada','Respondida','Aprobada','Aceptada por el cliente','Rechazada','Expirada','Pagada')),
    FOREIGN KEY (Rut) REFERENCES Usuario(Rut)
);

CREATE TABLE Detalle_Cotizacion (
    id_detalle_cotizacion INT           PRIMARY KEY,
    cantidad              INT           NOT NULL,
    precio_unitario       DECIMAL(10,2) NOT NULL,
    id_cotizacion         INT           NOT NULL,
    id_producto           INT,
    id_servicio           INT,
    CONSTRAINT chk_detcot_cantidad CHECK (cantidad >= 0),
    CONSTRAINT chk_detcot_precio   CHECK (precio_unitario >= 0),
    FOREIGN KEY (id_cotizacion) REFERENCES Cotizacion(id_cotizacion),
    FOREIGN KEY (id_producto)   REFERENCES Producto(id_producto),
    FOREIGN KEY (id_servicio)   REFERENCES Servicio(id_servicio)
);

CREATE TABLE Medio_pago (
    id_medio_pago          INT         PRIMARY KEY,
    tipo_pago              VARCHAR(50),
    ultimos_4_digitos      VARCHAR(4),
    fecha                  DATE,
    referencia_transaccion VARCHAR(50) NOT NULL,
    FOREIGN KEY (referencia_transaccion) REFERENCES Transaccion(Referencia_transaccion)
);

CREATE TABLE Compra (
    id_compra             INT           PRIMARY KEY,
    fecha_compra          DATE          NOT NULL,
    moneda                VARCHAR(10)   NOT NULL,
    modalidad_entrega     VARCHAR(20)   NOT NULL,
    total_neto            DECIMAL(10,2) NOT NULL,
    total_iva             DECIMAL(10,2) NOT NULL,
    total_pagado          DECIMAL(10,2) NOT NULL,
    rut                   VARCHAR(15)   NOT NULL,
    id_medio_pago         INT           NOT NULL,
    CONSTRAINT chk_compra_fecha    CHECK (fecha_compra >= '1995-01-01'),
    CONSTRAINT chk_compra_total    CHECK (total_pagado >= 0),
    CONSTRAINT chk_compra_modalidad CHECK (modalidad_entrega IN ('Despacho','Retiro')),
    FOREIGN KEY (rut)                   REFERENCES Usuario(Rut),
    FOREIGN KEY (id_medio_pago)         REFERENCES Medio_pago(id_medio_pago)
);

CREATE TABLE Detalle_Compra (
    id_detalle_compra INT           PRIMARY KEY,
    cantidad          INT           NOT NULL,
    precio_vendido    DECIMAL(10,2) NOT NULL,
    id_compra         INT           NOT NULL,
    id_producto       INT,
    id_servicio       INT,
    CONSTRAINT chk_detcomp_cantidad CHECK (cantidad >= 0),
    CONSTRAINT chk_detcomp_precio   CHECK (precio_vendido >= 0),
    FOREIGN KEY (id_compra)   REFERENCES Compra(id_compra),
    FOREIGN KEY (id_producto) REFERENCES Producto(id_producto),
    FOREIGN KEY (id_servicio) REFERENCES Servicio(id_servicio)
);

-- ============================================================
-- DEVOLUCION Y REEMBOLSO
-- ============================================================

CREATE TABLE Reembolso (
    id_reembolso      INT           PRIMARY KEY,
    monto_reembolsado DECIMAL(10,2) NOT NULL,
    metodo_reembolso  VARCHAR(50)   NOT NULL,
    id_compra         INT           NOT NULL UNIQUE,
    CONSTRAINT chk_reembolso_monto CHECK (monto_reembolsado >= 0),
    FOREIGN KEY (id_compra) REFERENCES Compra(id_compra)
);

CREATE TABLE Devolucion (
    id_devolucion     INT         PRIMARY KEY,
    fecha_solicitud   DATE,
    motivo            VARCHAR(100),
    estado_devolucion VARCHAR(20),
    id_compra         INT         NOT NULL,
    rut               VARCHAR(15) NOT NULL,
    id_reembolso      INT,
    CONSTRAINT chk_devol_fecha  CHECK (fecha_solicitud IS NULL OR fecha_solicitud >= '1995-01-01'),
    CONSTRAINT chk_devol_estado CHECK (estado_devolucion IN ('Aprobada','Pendiente','Rechazada')),
    FOREIGN KEY (id_compra)    REFERENCES Compra(id_compra),
    FOREIGN KEY (rut)          REFERENCES Usuario(Rut),
    FOREIGN KEY (id_reembolso) REFERENCES Reembolso(id_reembolso)
);

-- ============================================================
-- ENVÍO
-- ============================================================

CREATE TABLE Envio (
    id_envio               VARCHAR(50) PRIMARY KEY,
    id_direccion           INT         NOT NULL,
    fecha_envio            DATE,
    fecha_entrega_estimada DATE,
    estado_envio           VARCHAR(20),
    codigo_seguimiento     VARCHAR(30),
    id_compra              INT         NOT NULL,
    CONSTRAINT chk_envio_fecha     CHECK (fecha_envio IS NULL OR fecha_envio >= '1995-01-01'),
    CONSTRAINT chk_envio_fecha_est CHECK (fecha_entrega_estimada IS NULL OR fecha_entrega_estimada >= '1995-01-01'),
    CONSTRAINT chk_envio_fechas    CHECK (fecha_entrega_estimada IS NULL OR fecha_envio IS NULL OR fecha_entrega_estimada > fecha_envio),
    CONSTRAINT chk_envio_estado    CHECK (estado_envio IN ('Recibido','En Preparación','Enviado','Entregado')),
    FOREIGN KEY (id_direccion)       REFERENCES Direccion(id_direccion),
    FOREIGN KEY (codigo_seguimiento) REFERENCES Seguimiento(Codigo_seguimiento),
    FOREIGN KEY (id_compra)          REFERENCES Compra(id_compra)
);

-- ============================================================
-- RESEÑAS Y FAVORITOS (WISHLIST)
-- ============================================================

CREATE TABLE Resena (
    id_resena   INT PRIMARY KEY,
    puntaje     INT NOT NULL,
    comentario  TEXT,
    rut_cliente VARCHAR(15) NOT NULL,
    id_producto INT,
    id_servicio INT,
    rut_emprendedor VARCHAR(15),
    CONSTRAINT chk_resena_puntaje CHECK (puntaje >= 1 AND puntaje <= 5),
    FOREIGN KEY (rut_cliente) REFERENCES Usuario(Rut),
    FOREIGN KEY (rut_emprendedor) REFERENCES Usuario(Rut),
    FOREIGN KEY (id_producto) REFERENCES Producto(id_producto),
    FOREIGN KEY (id_servicio) REFERENCES Servicio(id_servicio)
);

CREATE TABLE Wishlist (
    id_wishlist INT PRIMARY KEY,
    rut         VARCHAR(15) NOT NULL,
    id_producto INT,
    id_servicio INT,
    fecha_agregada DATE,
    FOREIGN KEY (rut) REFERENCES Usuario(Rut),
    FOREIGN KEY (id_producto) REFERENCES Producto(id_producto),
    FOREIGN KEY (id_servicio) REFERENCES Servicio(id_servicio)
);

CREATE TABLE Trata_Pregunta_Producto (
    id_producto INT         NOT NULL,
    id_pregunta VARCHAR(20) NOT NULL,
    PRIMARY KEY (id_producto, id_pregunta),
    FOREIGN KEY (id_producto) REFERENCES Producto(id_producto),
    FOREIGN KEY (id_pregunta) REFERENCES Pregunta(id_pregunta)
);

CREATE TABLE Trata_Pregunta_Servicio (
    id_servicio INT         NOT NULL,
    id_pregunta VARCHAR(20) NOT NULL,
    PRIMARY KEY (id_servicio, id_pregunta),
    FOREIGN KEY (id_servicio) REFERENCES Servicio(id_servicio),
    FOREIGN KEY (id_pregunta) REFERENCES Pregunta(id_pregunta)
);

