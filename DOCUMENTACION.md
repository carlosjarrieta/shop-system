# Documentación del Proyecto: Sistema de Pedidos (Microservicios)

Este documento registra las decisiones arquitectónicas, configuración y gemas utilizadas en el proyecto.

## Arquitectura General
El proyecto sigue una **Arquitectura de Microservicios** orquestada mediante Docker Compose.
- **Orquestador**: Docker Compose (maneja la red y volúmenes).
- **Comunicación Síncrona**: REST API (HTTP) entre servicios.
- **Comunicación Asíncrona**: RabbitMQ (Event-Driven Architecture).

## Diagrama de Arquitectura y Flujo

Este esquema visual representa la interacción entre servicios, bases de datos y el broker de mensajería.



```text
[ CLIENTE (Postman/Curl) ]
          |
          | (1) POST /orders (Síncrono)
          v
+-----------------------+          (2) HTTP GET /customers/:id          +-----------------------+
|    ORDER SERVICE      | -------------------------------------------> |   CUSTOMER SERVICE    |
|   (Puerto 3001)       | <------------------------------------------- |    (Puerto 3000)      |
+-----------------------+          (Respuesta: "Existe/No Existe")      +-----------------------+
    ^     |                                                                        |
    |     | (3) Persiste Orden (pending)                                           | (5) Lee/Escribe
    |     v                                                                        v
    |  +-----------------------+                                                +-----------------------+
    |  |   DB_ORDERS (Postgres)|                                                | DB_CUSTOMERS(Postgres)|
    |  |   (Puerto 5434)       |                                                |    (Puerto 5433)      |
    |  +-----------------------+                                                +-----------------------+
    |           |                                                                  |
    |           | (4) EVENTO: "order.created" (Asíncrono)                          |
    |           v                                                                  |
    |  +-----------------------+                                                   |
    |  |       RABBITMQ        | <-------------------------------------------------+
    |  |    (Message Broker)   |      (7) EVENTO: "order.processed" (Feedback) 
    |  +-----------------------+
    |           |               
    +-----------+ (6) Consume Evento y actualiza status a "completed"
                  v
         +-----------------------+
         |   ORDER_WORKER        | --(Calls)--> [ CompleteOrderService ]
         |  (Rake Task)          |
         +-----------------------+
```

### 🔁 El Flujo del Bonus (Feedback Loop)
1. El **Customer Service** procesa el aumento del contador.
2. Al finalizar con éxito, emite un evento `order.processed`.
3. El **Order Service** lo escucha y actualiza el estado de la orden de `pending` a `completed`.
4. Esto garantiza **Consistencia Eventual Bi-direccional**.



### Gestión de Variables de Entorno (.env)
Actualmente, utilizamos un archivo `.env` centralizado en la raíz para la configuración de la **Infraestructura** (Docker Compose).
- **Ventaja (DX)**: Facilita el levantamiento de todo el entorno con `docker compose up`.
- **Consideración Arquitectónica**: En un entorno de producción real, cada servicio tendría sus propias variables inyectadas (ej. Kubernetes Secrets, AWS Parameter Store) para mantener el principio de **mínimo privilegio**.
- **Decisión**: Para esta prueba técnica y desarrollo local, mantenemos el `.env` centralizado para Docker, inyectando las variables a los contenedores.

## Servicios

### 1. Customer Service
Servicio encargado de la gestión de clientes.
- **Stack**: Ruby on Rails API.
- **Base de Datos**: PostgreSQL (`shop_customers`). Contenedor Dedicado (`db_customers`, port 5433).

#### Gemas Adicionales
| Gema | Versión | Propósito |
| :--- | :--- | :--- |
| `bunny` | ~> 2.19 | Cliente de RabbitMQ. Permite conectarse al broker para consumir eventos (ej: actualizar contador de pedidos). |
| `faker` | ~> 3.6 | Generación de datos falsos realistas para Seeds y Tests. |
| `jbuilder` | (Default) | Construcción de respuestas JSON estructuradas. |
| `rspec-rails` | ~> 6.0 | Framework de pruebas (BDD). Estándar de la industria en Ruby. |

### 2. Order Service
Servicio encargado de la creación y gestión de pedidos.
- **Stack**: Ruby on Rails API.
- **Base de Datos**: PostgreSQL (`shop_orders`). Contenedor Dedicado (`db_orders`, port 5434).

#### Gemas Adicionales
| Gema | Versión | Propósito |
| :--- | :--- | :--- |
| `bunny` | ~> 2.19 | Cliente de RabbitMQ. Usado para **Publicar** eventos (`order.created`). |
| `httparty` | ~> 0.22 | Cliente HTTP para comunicación con otros microservicios (interfaz limpia). |
| `rspec-rails` | ~> 6.0 | Framework de pruebas. |

## Instrucciones de Ejecución
Para ver el sistema en acción, consulta el archivo `README.md` con las guías de terminal.
