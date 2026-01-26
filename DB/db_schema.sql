-- Create the database
DROP DATABASE IF EXISTS gestion_formacion;
CREATE DATABASE gestion_formacion;

USE gestion_formacion;

-- Table for Regionals
CREATE TABLE IF NOT EXISTS regional (
    cod_regional INT PRIMARY KEY,
    nombre VARCHAR(100) NOT NULL
);

--  Table for Roles
CREATE TABLE IF NOT EXISTS rol (
    id_rol INT PRIMARY KEY,
    nombre VARCHAR(50) NOT NULL UNIQUE
);

-- Table for Competencies (Competencias)
CREATE TABLE IF NOT EXISTS competencia (
    cod_competencia INT PRIMARY KEY,
    nombre VARCHAR(500) NOT NULL,
    horas INT DEFAULT 0
);

-- Table for Holidays (Festivos)
CREATE TABLE IF NOT EXISTS festivos (
    festivo DATE PRIMARY KEY
);

-- Table for Training Programs (Programas)
CREATE TABLE IF NOT EXISTS programa_formacion (
    cod_programa INT NOT NULL,
    la_version INT NOT NULL,
    nombre VARCHAR(255) NOT NULL,
    horas_lectivas INT DEFAULT 0,
    horas_productivas INT DEFAULT 0,
    PRIMARY KEY (cod_programa, la_version)
);

-- Table for Training Centers (Centro de Formación)
CREATE TABLE IF NOT EXISTS centro_formacion (
    cod_centro INT PRIMARY KEY,
    nombre_centro VARCHAR(80) NOT NULL,
    cod_regional INT NOT NULL,
    CONSTRAINT fk_centro_regional FOREIGN KEY (cod_regional) REFERENCES regional(cod_regional)
);

-- Table for Users (Instructors/Admins)
CREATE TABLE IF NOT EXISTS usuario (
    id_usuario INT AUTO_INCREMENT PRIMARY KEY,
    nombre_completo VARCHAR(80) NOT NULL,
    identificacion VARCHAR(12) NOT NULL UNIQUE,
    id_rol INT NOT NULL,
    correo VARCHAR(100) NOT NULL UNIQUE,
    tipo_contrato VARCHAR(50) NOT NULL,
    telefono VARCHAR(15),
    estado BOOLEAN DEFAULT TRUE,
    cod_centro INT NOT NULL,
    pass_hash VARCHAR(255) NOT NULL,
    password_changed_at DATETIME DEFAULT CURRENT_TIMESTAMP  ,
    CONSTRAINT fk_usuario_rol FOREIGN KEY (id_rol) REFERENCES rol(id_rol),
    CONSTRAINT fk_usuario_centro FOREIGN KEY (cod_centro) REFERENCES centro_formacion(cod_centro)
);

-- Table for Training Environments (Ambientes)
CREATE TABLE IF NOT EXISTS ambiente_formacion (
    id_ambiente INT AUTO_INCREMENT PRIMARY KEY,
    nombre_ambiente VARCHAR(40) NOT NULL,
    num_max_aprendices INT NOT NULL,
    municipio VARCHAR(40) NOT NULL,
    ubicacion VARCHAR(80),
    cod_centro INT NOT NULL,
    estado BOOLEAN DEFAULT TRUE,
    CONSTRAINT fk_ambiente_centro FOREIGN KEY (cod_centro) REFERENCES centro_formacion(cod_centro)
);

-- Junction Table: Program and Competencies
CREATE TABLE IF NOT EXISTS programa_competencia (
    cod_prog_competencia INT AUTO_INCREMENT PRIMARY KEY,
    cod_programa INT NOT NULL, 
    la_version INT NOT NULL,
    cod_competencia INT NOT NULL,
    CONSTRAINT fk_pc_programa FOREIGN KEY (cod_programa, la_version) REFERENCES programa_formacion(cod_programa, la_version),
    CONSTRAINT fk_pc_competencia FOREIGN KEY (cod_competencia) REFERENCES competencia(cod_competencia)
);

-- Table for Learning Outcomes (Resultados de Aprendizaje)
CREATE TABLE IF NOT EXISTS resultado_aprendizaje (
    cod_resultado INT PRIMARY KEY,
    nombre VARCHAR(500) NOT NULL,
    cod_competencia INT NOT NULL,
    CONSTRAINT fk_resultado_competencia FOREIGN KEY (cod_competencia) REFERENCES competencia(cod_competencia)
);

-- Table for Groups (Grupos/Fichas)
-- archivo PE04 
CREATE TABLE IF NOT EXISTS grupo (
    cod_ficha INT PRIMARY KEY,
    cod_centro INT NOT NULL,
    cod_programa INT NOT NULL,
    la_version INT NOT NULL,
    estado_grupo VARCHAR(50),
    nombre_nivel VARCHAR(50),
    jornada VARCHAR(30),
    fecha_inicio DATE,
    fecha_fin DATE,
    etapa VARCHAR(50),
    modalidad VARCHAR(50),
    responsable VARCHAR(100),
    nombre_empresa VARCHAR(100),
    nombre_municipio VARCHAR(50),
    nombre_programa_especial VARCHAR(100),
    hora_inicio TIME,
    hora_fin TIME,
    id_ambiente INT,
    CONSTRAINT fk_grupo_centro FOREIGN KEY (cod_centro) REFERENCES centro_formacion(cod_centro),
    CONSTRAINT fk_grupo_programa FOREIGN KEY (cod_programa, la_version) REFERENCES programa_formacion(cod_programa, la_version),
    CONSTRAINT fk_grupo_ambiente FOREIGN KEY (id_ambiente) REFERENCES ambiente_formacion(id_ambiente)
);

-- Table for Group Data (Datos Grupo)
CREATE TABLE IF NOT EXISTS datos_grupo(
    cod_ficha INT PRIMARY KEY,
    num_aprendices_masculinos INT DEFAULT 0,
    num_aprendices_femenino INT DEFAULT 0,
    num_aprendices_no_binario INT DEFAULT 0,
    num_total_aprendices INT DEFAULT 0,
    num_total_aprendices_activos INT DEFAULT 0,
    cupo_total INT DEFAULT 0,
    en_transito INT DEFAULT 0,
    induccion INT DEFAULT 0,
    formacion INT DEFAULT 0,
    condicionado INT DEFAULT 0,
    aplazado INT DEFAULT 0,
    retiro_voluntario INT DEFAULT 0,
    cancelado INT DEFAULT 0,
    cancelamiento_vit_comp INT DEFAULT 0,
    desercion_vit_comp INT DEFAULT 0,
    por_certificar INT DEFAULT 0,
    certificados INT DEFAULT 0,
    traslados INT DEFAULT 0,
    otro INT DEFAULT 0,
    CONSTRAINT fk_dg_grupo FOREIGN KEY(cod_ficha) REFERENCES grupo(cod_ficha)
);

-- Table for Instructor Assignments to Groups
CREATE TABLE IF NOT EXISTS grupo_instructor (
    cod_ficha INT NOT NULL,
    id_instructor INT NOT NULL,
    PRIMARY KEY (cod_ficha, id_instructor),
    CONSTRAINT fk_gi_ficha FOREIGN KEY (cod_ficha) REFERENCES grupo(cod_ficha),
    CONSTRAINT fk_gi_instructor FOREIGN KEY (id_instructor) REFERENCES usuario(id_usuario)
);

-- Table for Scheduling (Programacion)
CREATE TABLE IF NOT EXISTS programacion (
    id_programacion INT AUTO_INCREMENT PRIMARY KEY,
    id_instructor INT NOT NULL,
    cod_ficha INT NOT NULL,
    fecha_programada DATE NOT NULL,
    horas_programadas INT NOT NULL,
    hora_inicio TIME NOT NULL,
    hora_fin TIME NOT NULL,
    cod_competencia INT NOT NULL,
    cod_resultado INT NOT NULL,
    id_user INT, -- User who created the schedule
    CONSTRAINT fk_prog_instructor FOREIGN KEY (id_instructor) REFERENCES usuario(id_usuario),
    CONSTRAINT fk_prog_ficha FOREIGN KEY (cod_ficha) REFERENCES grupo(cod_ficha),
    CONSTRAINT fk_prog_competencia FOREIGN KEY (cod_competencia) REFERENCES competencia(cod_competencia),
    CONSTRAINT fk_prog_resultado FOREIGN KEY (cod_resultado) REFERENCES resultado_aprendizaje(cod_resultado),
    CONSTRAINT fl_prog_usuario FOREIGN KEY(id_user) REFERENCES usuario(id_usuario)

);

-- Table for Notifications
CREATE TABLE IF NOT EXISTS notificacion (
    id_notificacion INT AUTO_INCREMENT PRIMARY KEY,
    id_usuario INT NOT NULL,
    mensaje TEXT NOT NULL,
    leida BOOLEAN DEFAULT FALSE,
    fecha_creacion DATETIME DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_notificacion_usuario FOREIGN KEY (id_usuario) REFERENCES usuario(id_usuario)
);

-- Table for Goals (Metas)
CREATE TABLE IF NOT EXISTS metas(
    id_meta INT AUTO_INCREMENT PRIMARY KEY,
    anio YEAR,
    cod_centro INT,
    concepto VARCHAR(100),
    valor INT,
    CONSTRAINT fk_metas_cf FOREIGN KEY(cod_centro) REFERENCES centro_formacion(cod_centro)
);


-- INSERTS
-- Insert sample regional
INSERT INTO regional(cod_regional,nombre) VALUES (66, 'REGIONAL RISARALDA');

-- Insert sample training center
INSERT INTO centro_formacion(cod_centro, nombre_centro, cod_regional)
VALUES (9121, 'CENTRO ATENCION SECTOR AGROPECUARIO', 66);

-- Insert rols
INSERT INTO rol (id_rol, nombre) VALUES 
(1, 'superadmin'),
(2, 'admin'),
(3, 'instructor');

-- Insert a sample user (superadmin)
INSERT INTO usuario (nombre_completo, identificacion, id_rol, correo, tipo_contrato, telefono, cod_centro, pass_hash)
VALUES ('superadmin', '123456789', 1, 'super@example.com', 'Indefinido', '3001234567', 9121, '$2b$12$/M0Q68S4r9/aS7z9Qwxez.Cpui5SRaHWIR6WEMKuWz5YBBkeMCXey');

-- Insert a sample user (admin)
INSERT INTO usuario (nombre_completo, identificacion, id_rol, correo, tipo_contrato, telefono, cod_centro, pass_hash)
VALUES ('admin', '123456780', 2, 'admin@example.com', 'Indefinido', '3001234567', 9121, '$2b$12$/M0Q68S4r9/aS7z9Qwxez.Cpui5SRaHWIR6WEMKuWz5YBBkeMCXey');

-- Insert a sample user (instructor)
INSERT INTO usuario (nombre_completo, identificacion, id_rol, correo, tipo_contrato, telefono, cod_centro, pass_hash)
VALUES ('instructor', '123456781', 3, 'instru@example.com', 'Indefinido', '3001234567', 9121, '$2b$12$/M0Q68S4r9/aS7z9Qwxez.Cpui5SRaHWIR6WEMKuWz5YBBkeMCXey');
