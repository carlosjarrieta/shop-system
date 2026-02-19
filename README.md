# Prueba Técnica: Sistema de Microservicios (Orders & Customers)

Este proyecto implementa un sistema de gestión de pedidos y clientes utilizando una arquitectura distribuida y orientada a eventos.

## 🚀 Guía de Inicio Rápido

### 1. Requisitos Previos
- Docker y Docker Compose.
- Ruby 3.2.2.
- PostgreSQL (Ejecutándose vía Docker).

### 2. Infraestructura (Docker)
Levantar las bases de datos (aisladas) y el broker de mensajería:
```bash
docker compose up -d
```

### 3. Setup de los Servicios
Ejecutar en terminales separadas:

**Customer Service:**
```bash
cd customer_service
bundle install
rails db:create db:migrate db:seed
rails s -p 3000
```

**Order Service:**
```bash
cd order_service
bundle install
rails db:create db:migrate
rails s -p 3001
```

**RabbitMQ Consumer (Worker):**
```bash
cd customer_service
rake rabbitmq:consume
```

## 🏗️ Arquitectura
Para una explicación detallada de los patrones de diseño (Gateway, Command, EDA) y diagramas de flujo, consulta:
👉 **[DOCUMENTACION.md](./DOCUMENTACION.md)**
