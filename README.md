# Proyecto Bases de Datos II - Plataforma "Voluntariado"

Este repositorio contiene el diseño, estructuración e implementación del sistema de base de datos relacional para la plataforma de gestión social y comunitaria **Voluntariado**. Este proyecto toma como base un diseño inicial y lo extiende aplicando conceptos avanzados de Bases de Datos II, tales como triggers (desencadenadores), tablas transaccionales de auditoría y mecanismos de moderación.

---

## 1. Enunciado del Problema a Sistematizar (Entrega 1)

### Contexto y Necesidades Detectadas
En la actualidad, las organizaciones sin fines de lucro y los ciudadanos interesados en realizar labores sociales carecen de un canal centralizado, seguro y eficiente para coordinar actividades de voluntariado. Las organizaciones enfrentan serios inconvenientes técnicos para publicar sus campañas de forma geolocalizada, controlar dinámicamente el aforo (cupos disponibles) y realizar la trazabilidad o validación de la asistencia real de los participantes. Por otro lado, los voluntarios carecen de un historial consolidado y transparente de sus horas acreditadas, así como de un canal directo, ordenado y seguro para comunicarse con las instituciones organizadoras.

Adicionalmente, desde la perspectiva de la seguridad informática y la gestión de la comunidad (módulos críticos de **Usuarios y Comunicaciones**), se identificó la necesidad de auditar de forma automática todos los accesos y modificaciones en las credenciales críticas de las cuentas de usuario para mitigar riesgos de suplantación. Del mismo modo, debido a la interacción directa entre usuarios dentro del chat, se requiere un mecanismo técnico en el motor de la base de datos para reportar comportamientos fraudulentos (como spam o acoso), garantizando así la moderación de la comunidad y la integridad del ecosistema informático.

### Alcance del Sistema
El sistema automatiza el control de acceso segmentado por roles (Administradores, Voluntarios, Organizaciones), el aprovisionamiento de perfiles especializados (relaciones 1:1), la publicación geográfica de actividades por categorías, la gestión transaccional de inscripciones con actualización en cascada de cupos disponibles, un sistema cerrado de mensajería interna parametrizado por actividad, y módulos avanzados de seguridad (auditoría automática) y moderación (reporte de incidencias).

---

## 2. Desarrollo Técnico y Arquitectura de Datos

### 2.1 Nombre de la Base de Datos
* **Nombre:** `voluntariado`

### 2.2 Listado y Clasificación de Tablas (14 Tablas en Total)
Para cumplir con los estándares de la materia, la base de datos ha sido estructurada separando las tablas maestras/catálogos (**Referenciales**) de los flujos de información operativa y transaccional (**De Movimiento**).

#### Tablas Referenciales (Catálogos y Perfiles de Extensión)
1. **`ROL`**: Define los niveles de acceso del sistema (`Administrador`, `Voluntario`, `Organizacion`).
2. **`CIUDAD`**: Registro geográfico estático (Municipio y Departamento) para zonificación.
3. **`CATEGORIA`**: Clasificación del enfoque social de las actividades (`Medio Ambiente`, `Educación`, `Salud`).
4. **`PERFIL_VOLUNTARIO`**: Datos demográficos y áreas de interés específicas del ciudadano voluntario.
5. **`PERFIL_ORGANIZACION`**: Datos institucionales, NIT y estado de verificación legal de las fundaciones.
6. **`PERFIL_ADMIN`**: Registro e identificación del personal interno administrativo de la plataforma.

#### Tablas de Movimiento (Transacciones, Logs y Comunicaciones)
7. **`USUARIO`**: Entidad central de autenticación (Llave de entrada con relaciones 1:1 hacia perfiles).
8. **`ACTIVIDAD`**: Eventos o campañas sociales publicadas con control de estados y fechas.
9. **`INSCRIPCION`**: Registro transaccional de la postulación de un voluntario a una actividad con acreditación de horas.
10. **`RESENA`**: Calificaciones numéricas y comentarios de retroalimentación post-evento.
11. **`MENSAJE`**: Chat bidireccional asincrónico entre usuarios con metadatos de lectura y referencia de actividad.
12. **`NOTIFICACION`**: Repositorio de alertas del sistema enviadas a los usuarios por eventos clave.
13. **`AUDITORIA_USUARIO`**: **(Nueva - Bases II)** Registro automatizado (Log) de operaciones críticas de seguridad.
14. **`REPORTE_USUARIO`**: **(Nueva - Bases II)** Registro transaccional de denuncias entre usuarios por moderación.

---

## 3. Diccionario de Datos (Módulos Críticos)

### Tabla: USUARIO
* `id_usuario` (INT, PK, AutoIncrement): Identificador único de la cuenta.
* `correo_electronico` (VARCHAR(100), UNIQUE, NOT NULL): Correo de inicio de sesión.
* `contrasena` (VARCHAR(255), NOT NULL): Clave de acceso encriptada.
* `fecha_registro` (DATETIME, DEFAULT CURRENT_TIMESTAMP): Fecha y hora de creación de la cuenta.
* `id_rol` (INT, FK -> ROL): Rol que determina los permisos del usuario.
* `id_ciudad` (INT, FK -> CIUDAD, NULL): Ciudad base del usuario.

### Tabla: AUDITORIA_USUARIO
* `id_auditoria` (INT, PK, AutoIncrement): Identificador único del evento auditado.
* `id_usuario` (INT, NOT NULL): ID de la cuenta que sufrió la alteración informática.
* `accion` (VARCHAR(20), NOT NULL): Tipo de operación interceptada (`REGISTRO`, `CAMBIO_CONTRASENA`).
* `correo_afectado` (VARCHAR(100)): Respaldo del correo del usuario al momento de la transacción.
* `fecha_movimiento` (DATETIME, DEFAULT CURRENT_TIMESTAMP): Estampa de tiempo exacta del disparo del trigger.
* `detalles` (VARCHAR(255)): Descripción del evento técnico registrado.

### Tabla: REPORTE_USUARIO
* `id_reporte` (INT, PK, AutoIncrement): Código único del reporte de moderación.
* `motivo` (VARCHAR(255), NOT NULL): Razón o argumento de la denuncia (ej. Spam, acoso, enlace malicioso).
* `fecha_reporte` (DATETIME, DEFAULT CURRENT_TIMESTAMP): Fecha y hora del radicado de la queja.
* `id_usuario_reporta` (INT, FK -> USUARIO): Identificador del usuario que emite la queja.
* `id_usuario_reportado` (INT, FK -> USUARIO): Identificador del presunto infractor.

---

## 4. Automatización Implementada (Triggers)
El script incluye la creación de dos disparadores avanzados en MySQL para blindar la seguridad:
* **`tg_auditoria_nuevo_usuario`**: Intercepta inserciones en la tabla `USUARIO` de forma asíncrona (`AFTER INSERT`) y genera automáticamente la traza de auditoría de bienvenida.
* **`tg_auditoria_cambio_clave`**: Evalúa actualizaciones (`BEFORE UPDATE`) en las credenciales de acceso. Si el hash de la contraseña cambia, captura la modificación de forma inmediata y almacena el registro histórico preventivo.
