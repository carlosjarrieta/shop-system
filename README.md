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

**Levantar Consumidores (Workers de Background):**
Para que la coreografía de eventos (Saga Pattern) funcione correctamente y los estados se actualicen, debes mantener corriendo los consumidores de RabbitMQ en dos terminales adicionales.

👉 **Worker 1 (Customer Service):** Escucha `order.created` y suma saldo al cliente.
```bash
cd customer_service
bundle exec rake rabbitmq:consume
```

👉 **Worker 2 (Order Service):** Escucha `order.processed` y pasa la orden a `completed`.
```bash
cd order_service
bundle exec rake rabbitmq:consume_responses
```

## 🏗️ Arquitectura y Patrones Aplicados
Para una explicación muy detallada del porqué de las decisiones, los Patrones Solid, **Service Objects** (Command Pattern), Inyección de Dependencias y el **Flujo de Feedback Bidireccional** implementado, consulta:
👉 **[DOCUMENTACION.md](./DOCUMENTACION.md)**

### 🧪 Pruebas Unitarias Aisladas (RSpec & WebMock)
Ambos microservicios cuentan con 100% de cobertura en sus casos de uso core, aislando HTTP y a RabbitMQ del entorno.
```bash
# Order Service Tests
cd order_service && RAILS_ENV=test bundle exec rake db:prepare && bundle exec rspec
# Customer Service Tests
cd customer_service && RAILS_ENV=test bundle exec rake db:prepare && bundle exec rspec
```

### 🛠️ Pruebas Manuales (Postman / Insomnia)
Para facilitar la verificación del sistema, he incluido una colección lista para importar en la raíz del proyecto:
👉 **`shop_system_collection.json`**

Al importarla en tu cliente HTTP preferido (Postman o Insomnia), tendrás todos los endpoints listos para realizar el flujo de creación de clientes y órdenes con un solo clic.
