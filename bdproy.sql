CREATE DATABASE IF NOT EXISTS voluntariado
  CHARACTER SET utf8mb4
  COLLATE utf8mb4_unicode_ci;

USE voluntariado;

CREATE TABLE IF NOT EXISTS ROL (
  id_rol      INT PRIMARY KEY AUTO_INCREMENT,
  nombre_rol  VARCHAR(50) NOT NULL UNIQUE
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS CIUDAD (
  id_ciudad     INT PRIMARY KEY AUTO_INCREMENT,
  nombre_ciudad VARCHAR(100) NOT NULL,
  departamento  VARCHAR(100)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS CATEGORIA (
  id_categoria     INT PRIMARY KEY AUTO_INCREMENT,
  nombre_categoria VARCHAR(50) NOT NULL UNIQUE,
  descripcion      VARCHAR(255)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS USUARIO (
  id_usuario          INT PRIMARY KEY AUTO_INCREMENT,
  correo_electronico  VARCHAR(100) NOT NULL UNIQUE,
  contrasena          VARCHAR(255) NOT NULL,
  fecha_registro      DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  id_rol              INT NOT NULL,
  id_ciudad           INT,
  CONSTRAINT fk_usuario_rol    FOREIGN KEY (id_rol)    REFERENCES ROL(id_rol),
  CONSTRAINT fk_usuario_ciudad FOREIGN KEY (id_ciudad) REFERENCES CIUDAD(id_ciudad)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS PERFIL_VOLUNTARIO (
  id_voluntario INT PRIMARY KEY AUTO_INCREMENT,
  nombre        VARCHAR(100) NOT NULL,
  apellido      VARCHAR(100) NOT NULL,
  telefono      VARCHAR(20),
  intereses     TEXT,
  id_usuario    INT NOT NULL UNIQUE,
  CONSTRAINT fk_pv_usuario FOREIGN KEY (id_usuario) REFERENCES USUARIO(id_usuario) ON DELETE CASCADE
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS PERFIL_ORGANIZACION (
  id_organizacion    INT PRIMARY KEY AUTO_INCREMENT,
  nombre_institucion VARCHAR(150) NOT NULL,
  nit_registro       VARCHAR(50) NOT NULL UNIQUE,
  telefono           VARCHAR(20),
  descripcion_org    TEXT,
  estado_activo      BOOLEAN NOT NULL DEFAULT TRUE,
  estado_verificacion VARCHAR(20) NOT NULL DEFAULT 'PENDIENTE',
  id_usuario         INT NOT NULL UNIQUE,
  CONSTRAINT fk_po_usuario FOREIGN KEY (id_usuario) REFERENCES USUARIO(id_usuario) ON DELETE CASCADE
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS PERFIL_ADMIN (
  id_admin      INT PRIMARY KEY AUTO_INCREMENT,
  nombre        VARCHAR(100) NOT NULL,
  apellido      VARCHAR(100) NOT NULL,
  nivel_acceso  VARCHAR(50) NOT NULL DEFAULT 'GENERAL',
  id_usuario    INT NOT NULL UNIQUE,
  CONSTRAINT fk_pa_usuario FOREIGN KEY (id_usuario) REFERENCES USUARIO(id_usuario) ON DELETE CASCADE
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS ACTIVIDAD (
  id_actividad      INT PRIMARY KEY AUTO_INCREMENT,
  titulo            VARCHAR(150) NOT NULL,
  descripcion       TEXT,
  fecha_evento      DATETIME NOT NULL,
  direccion         VARCHAR(200),
  cupos_totales     INT NOT NULL DEFAULT 0,
  cupos_disponibles INT NOT NULL DEFAULT 0,
  estado_actividad  VARCHAR(20) NOT NULL DEFAULT 'PUBLICADA',
  imagen_url        LONGTEXT,
  id_organizacion   INT NOT NULL,
  id_categoria      INT NOT NULL,
  id_ciudad         INT NOT NULL,
  CONSTRAINT fk_act_org    FOREIGN KEY (id_organizacion) REFERENCES PERFIL_ORGANIZACION(id_organizacion) ON DELETE CASCADE,
  CONSTRAINT fk_act_cat    FOREIGN KEY (id_categoria)    REFERENCES CATEGORIA(id_categoria),
  CONSTRAINT fk_act_ciudad FOREIGN KEY (id_ciudad)       REFERENCES CIUDAD(id_ciudad)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS INSCRIPCION (
  id_inscripcion     INT PRIMARY KEY AUTO_INCREMENT,
  fecha_inscripcion  DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  estado_solicitud   VARCHAR(20) NOT NULL DEFAULT 'PENDIENTE',
  horas_acreditadas  INT NOT NULL DEFAULT 0,
  id_voluntario      INT NOT NULL,
  id_actividad       INT NOT NULL,
  CONSTRAINT fk_ins_vol UNIQUE (id_voluntario, id_actividad),
  CONSTRAINT fk_ins_voluntario FOREIGN KEY (id_voluntario) REFERENCES PERFIL_VOLUNTARIO(id_voluntario) ON DELETE CASCADE,
  CONSTRAINT fk_ins_actividad  FOREIGN KEY (id_actividad)  REFERENCES ACTIVIDAD(id_actividad) ON DELETE CASCADE
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS RESENA (
  id_resena      INT PRIMARY KEY AUTO_INCREMENT,
  calificacion   INT NOT NULL,
  comentario     TEXT,
  fecha_resena   DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  id_inscripcion INT NOT NULL,
  CONSTRAINT fk_res_ins FOREIGN KEY (id_inscripcion) REFERENCES INSCRIPCION(id_inscripcion) ON DELETE CASCADE,
  CONSTRAINT chk_res_calif CHECK (calificacion BETWEEN 1 AND 5)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS MENSAJE (
  id_mensaje              INT PRIMARY KEY AUTO_INCREMENT,
  contenido               TEXT NOT NULL,
  fecha_envio             DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  leido                   BOOLEAN NOT NULL DEFAULT FALSE,
  id_usuario_remitente    INT NOT NULL,
  id_usuario_destinatario INT NOT NULL,
  id_actividad            INT NULL,
  CONSTRAINT fk_msg_remitente    FOREIGN KEY (id_usuario_remitente)    REFERENCES USUARIO(id_usuario) ON DELETE CASCADE,
  CONSTRAINT fk_msg_destinatario FOREIGN KEY (id_usuario_destinatario) REFERENCES USUARIO(id_usuario) ON DELETE CASCADE,
  CONSTRAINT fk_msg_actividad    FOREIGN KEY (id_actividad)            REFERENCES ACTIVIDAD(id_actividad) ON DELETE SET NULL
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS NOTIFICACION (
  id_notificacion INT PRIMARY KEY AUTO_INCREMENT,
  titulo          VARCHAR(150) NOT NULL,
  mensaje         VARCHAR(500) NOT NULL,
  tipo            VARCHAR(40)  NOT NULL DEFAULT 'GENERAL',
  fecha_creacion  DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  leido           BOOLEAN NOT NULL DEFAULT FALSE,
  id_usuario      INT NOT NULL,
  CONSTRAINT fk_noti_usuario FOREIGN KEY (id_usuario) REFERENCES USUARIO(id_usuario) ON DELETE CASCADE
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS AUDITORIA_USUARIO (
  id_auditoria      INT PRIMARY KEY AUTO_INCREMENT,
  id_usuario        INT NOT NULL,
  accion            VARCHAR(20) NOT NULL,
  correo_afectado   VARCHAR(100),
  fecha_movimiento  DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  detalles          VARCHAR(255)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS REPORTE_USUARIO (
  id_reporte           INT PRIMARY KEY AUTO_INCREMENT,
  motivo               VARCHAR(255) NOT NULL,
  fecha_reporte        DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  id_usuario_reporta   INT NOT NULL,
  id_usuario_reportado INT NOT NULL,
  CONSTRAINT fk_rep_reporta   FOREIGN KEY (id_usuario_reporta)   REFERENCES USUARIO(id_usuario) ON DELETE CASCADE,
  CONSTRAINT fk_rep_reportado FOREIGN KEY (id_usuario_reportado) REFERENCES USUARIO(id_usuario) ON DELETE CASCADE
) ENGINE=InnoDB;

DELIMITER //

CREATE TRIGGER tg_auditoria_nuevo_usuario
AFTER INSERT ON USUARIO
FOR EACH ROW
BEGIN
  INSERT INTO AUDITORIA_USUARIO (id_usuario, accion, correo_afectado, detalles)
  VALUES (NEW.id_usuario, 'REGISTRO', NEW.correo_electronico, 'Se ha creado una nueva cuenta en el sistema.');
END //

CREATE TRIGGER tg_auditoria_cambio_clave
BEFORE UPDATE ON USUARIO
FOR EACH ROW
BEGIN
  IF OLD.contrasena <> NEW.contrasena THEN
    INSERT INTO AUDITORIA_USUARIO (id_usuario, accion, correo_afectado, detalles)
    VALUES (NEW.id_usuario, 'CAMBIO_CONTRASENA', NEW.correo_electronico, 'El usuario actualizó sus credenciales de acceso.');
  END IF;
END //

DELIMITER ;

-- =============================================
-- DATOS DE PRUEBA
-- =============================================

INSERT INTO ROL (nombre_rol) VALUES
('Administrador'),
('Voluntario'),
('Organizacion');

INSERT INTO CIUDAD (nombre_ciudad, departamento) VALUES
('Medellín', 'Antioquia'),
('Envigado', 'Antioquia'),
('Itagüí', 'Antioquia'),
('Bogotá', 'Cundinamarca');

INSERT INTO CATEGORIA (nombre_categoria, descripcion) VALUES
('Medio Ambiente', 'Reforestación, limpieza de ríos y cuidado animal.'),
('Educación', 'Tutorías a niños, alfabetización y talleres.'),
('Salud y Bienestar', 'Brigadas médicas, apoyo psicológico y donaciones.');

-- Los INSERT en USUARIO disparan automáticamente el trigger tg_auditoria_nuevo_usuario
-- id=1: admin | id=2: Tomás | id=3: org | id=4: Pedro | id=5..10: nuevos voluntarios
INSERT INTO USUARIO (correo_electronico, contrasena, id_rol, id_ciudad) VALUES
('admin.central@voluntariado.org',    'admin1234',   1, 1),
('tomas.voluntario@gmail.com',        'Tomas@2026',  2, 1),
('contacto@fundacionverde.org',       'OrgPass2026', 3, 1),
('usuario.problematico@gmail.com',    'SpamPass99',  2, 3),
('emmanuel.chaverra@gmail.com',       'Emm@2026',    2, 1),
('frozono.castillo@gmail.com',        'Froz@2026',   2, 4),
('jorge.espaguetti@gmail.com',        'Jorg@2026',   2, 3),
('daniel.canino@gmail.com',           'Dani@2026',   2, 2),
('freddy.maduro@gmail.com',           'Fred@2026',   2, 1),
('yoao.espriella@gmail.com',          'Yoao@2026',   2, 4);

INSERT INTO PERFIL_ADMIN (nombre, apellido, nivel_acceso, id_usuario) VALUES
('Carlos', 'Restrepo', 'SUPER_ADMIN', 1);

INSERT INTO PERFIL_VOLUNTARIO (nombre, apellido, telefono, intereses, id_usuario) VALUES
('Tomás',     'Urrego',            '3001234567', 'Desarrollo web, tecnología, ecología',              2),
('Pedro',     'Molesto',           '3151112233', 'Ninguno en específico',                             4),
('Emmanuel',  'Chaverra Gepete',   '3201234560', 'Educación comunitaria, tecnología social',          5),
('Frozono',   'Castillo Petro',    '3151234561', 'Medio ambiente, reforestación, ecología',           6),
('Jorge',     'Espaguetti Escobar','3101234562', 'Logística, deporte comunitario, eventos',           7),
('Daniel',    'Canino Kaelis',     '3181234563', 'Salud y bienestar, primeros auxilios',              8),
('Freddy',    'Maduro Palacios',   '3121234564', 'Arte y cultura, talleres juveniles, fotografía',    9),
('Yoao',      'Espriella Mosquera','3161234565', 'Comunicaciones, redes sociales, periodismo',       10);

INSERT INTO PERFIL_ORGANIZACION (nombre_institucion, nit_registro, telefono, descripcion_org, estado_activo, estado_verificacion, id_usuario) VALUES
('Fundación Planeta Verde', '900123456-1', '6044445566', 'Institución dedicada a la siembra de árboles nativos en el Valle de Aburrá.', 1, 'VERIFICADA', 3);

INSERT INTO ACTIVIDAD (titulo, descripcion, fecha_evento, direccion, cupos_totales, cupos_disponibles, estado_actividad, id_organizacion, id_categoria, id_ciudad) VALUES
('Sembratón Arví 2026', 'Jornada de reforestación en el Parque Arví. Traer ropa cómoda.', '2026-06-15 08:00:00', 'Parque Arví, Piedras Blancas', 50, 49, 'PUBLICADA', 1, 1, 1);

INSERT INTO INSCRIPCION (estado_solicitud, horas_acreditadas, id_voluntario, id_actividad) VALUES
('APROBADA', 4, 1, 1);

INSERT INTO MENSAJE (contenido, id_usuario_remitente, id_usuario_destinatario, id_actividad) VALUES
('Hola, ¿a qué hora sale el bus para la sembratón?', 2, 3, 1),
('Hola Tomás, salimos a las 7:00 AM desde la estación Caribe.', 3, 2, 1),
('GANA DINERO FÁCIL ENTRANDO A ESTE ENLACE TRUCHO!!!', 4, 2, NULL);

INSERT INTO REPORTE_USUARIO (motivo, id_usuario_reporta, id_usuario_reportado) VALUES
('El usuario está enviando enlaces extraños de publicidad por mensaje privado.', 2, 4);

SHOW TABLES;
