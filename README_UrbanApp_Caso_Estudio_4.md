# Caso de Estudio 4 --- App de Movilidad en Tiempo Real

## Empresa: UrbanApp

### Descripción del caso

UrbanApp es una aplicación de geolocalización y viajes con millones de
usuarios activos. El equipo técnico publica actualizaciones de la API
cada dos días.

Recientemente, una actualización de la API provocó una incompatibilidad
entre la aplicación móvil y el backend. Como consecuencia, miles de
conductores no pudieron finalizar sus viajes.

El objetivo de esta propuesta es establecer un proceso de **DevOps,
GitFlow, despliegue Canary, Feature Flags y CI/CD** que permita corregir
incidentes críticos rápidamente, reducir el riesgo de nuevas versiones y
medir la mejora del proceso.

------------------------------------------------------------------------

# 1. Análisis de la problemática

Los principales problemas detectados son:

1.  **Cambio de contrato de API sin retrocompatibilidad**
    -   El backend modificó una respuesta o endpoint que todavía era
        utilizado por versiones anteriores de la aplicación móvil.
    -   Las aplicaciones móviles no se actualizan al mismo tiempo que la
        API.
2.  **Falta de coordinación entre Mobile y Backend**
    -   Los equipos desarrollan y despliegan cambios sin un contrato
        compartido.
    -   No existe una validación automática de compatibilidad antes de
        producción.
3.  **Rollback lento**
    -   La versión anterior de la API no puede recuperarse rápidamente.
    -   El proceso depende de cambios manuales y puede aumentar el
        tiempo de indisponibilidad.
4.  **Despliegues con demasiado riesgo**
    -   Una nueva versión puede llegar inmediatamente a todos los
        usuarios.
    -   No existe una etapa controlada para detectar errores antes de
        ampliar el despliegue.

------------------------------------------------------------------------

# 2. Solución propuesta

La solución combina cinco prácticas:

  -----------------------------------------------------------------------
  Problema                            Solución
  ----------------------------------- -----------------------------------
  Cambios incompatibles en API        Versionado de API + contratos
                                      retrocompatibles

  Falta de coordinación               Pull Requests + pruebas de
                                      contrato + CI/CD

  Rollback lento                      Artefactos versionados + despliegue
                                      automatizado

  Riesgo de nuevas versiones          Canary Deployment

  Necesidad de activar/desactivar     Feature Flags
  funciones                           

  Falta de medición                   Métricas DORA
  -----------------------------------------------------------------------

## Arquitectura del proceso

``` mermaid
flowchart LR
    A[Desarrollador] --> B[GitFlow]
    B --> C[Pull Request]
    C --> D[CI]
    D --> E[Pruebas unitarias]
    D --> F[Pruebas de contrato API]
    D --> G[Pruebas de integración]
    E --> H[Build de artefacto]
    F --> H
    G --> H
    H --> I[Staging]
    I --> J[Canary 5%]
    J --> K{Métricas correctas?}
    K -- No --> L[Rollback]
    K -- Sí --> M[Canary 25%]
    M --> N[Canary 50%]
    N --> O[100% Producción]
    O --> P[Monitoreo]
```

------------------------------------------------------------------------

# 3. Gestión de Hotfixes con GitFlow

## Objetivo

Resolver un error crítico de producción en menos de 30 minutos sin
detener el desarrollo de nuevas funcionalidades.

La estrategia consiste en crear una rama `hotfix` directamente desde la
rama de producción, corregir el problema, ejecutar las pruebas,
desplegar y posteriormente sincronizar la solución con las ramas de
desarrollo.

## Estructura de ramas

``` text
main
│
├── release/2.8.0
│
├── develop
│   ├── feature/nueva-funcion
│   └── feature/mejora-mapas
│
└── hotfix/2.7.1-finalizar-viaje
```

### Convención

``` text
feature/<nombre>
release/<version>
hotfix/<version>-<descripcion>
```

------------------------------------------------------------------------

## Procedimiento del Hotfix

### Paso 1 --- Detectar el incidente

Se detecta que los conductores no pueden finalizar viajes.

Ejemplo:

``` text
ERROR API:
POST /api/v1/trips/{id}/finish

HTTP 500
```

Se crea el ticket:

``` text
INC-001
Error crítico al finalizar viajes
Prioridad: P1
```

------------------------------------------------------------------------

### Paso 2 --- Crear la rama Hotfix

La rama se crea desde la versión actualmente estable en producción:

``` bash
git checkout main
git pull origin main

git checkout -b hotfix/2.7.1-finalizar-viaje
```

------------------------------------------------------------------------

### Paso 3 --- Corregir el problema

La corrección debe ser pequeña y enfocada exclusivamente en el
incidente.

Ejemplo:

``` javascript
// Antes
const status = trip.status;

// Después
const status = trip.status ?? "completed";
```

Después:

``` bash
git add .
git commit -m "fix(api): corregir finalización de viajes"
```

------------------------------------------------------------------------

### Paso 4 --- Ejecutar pruebas

Antes de desplegar:

``` bash
npm test
npm run test:integration
npm run test:contract
```

También se debe comprobar específicamente:

``` text
POST /api/v1/trips/{id}/finish
```

Casos mínimos:

-   viaje válido
-   viaje ya finalizado
-   viaje inexistente
-   usuario no autorizado
-   respuesta compatible con la aplicación móvil anterior

------------------------------------------------------------------------

### Paso 5 --- Pull Request

Crear:

``` text
hotfix/2.7.1-finalizar-viaje → main
```

La revisión debe verificar:

-   alcance del cambio
-   pruebas
-   seguridad
-   compatibilidad de API
-   logs
-   impacto en la aplicación móvil

------------------------------------------------------------------------

### Paso 6 --- Generar artefacto versionado

No se debe reconstruir manualmente una versión diferente durante el
despliegue.

Ejemplo:

``` text
urbanapp-api:2.7.1
```

El artefacto debe quedar disponible para poder desplegarlo o retirarlo
rápidamente.

------------------------------------------------------------------------

### Paso 7 --- Desplegar

El pipeline realiza:

``` text
Build
 ↓
Tests
 ↓
Staging
 ↓
Canary
 ↓
Producción
```

Para un hotfix crítico se puede iniciar con un porcentaje reducido:

``` text
Canary: 5%
```

------------------------------------------------------------------------

### Paso 8 --- Validar

Monitorear:

-   HTTP 5xx
-   latencia
-   errores de finalización de viajes
-   solicitudes por minuto
-   consumo de CPU/memoria
-   logs de errores

Si las métricas son normales:

``` text
5% → 25% → 50% → 100%
```

Si aparecen errores:

``` text
Canary → Rollback
```

------------------------------------------------------------------------

### Paso 9 --- Sincronizar el cambio

Después de estabilizar producción:

``` bash
git checkout main
git pull origin main

git checkout develop
git pull origin develop

git merge main
git push origin develop
```

Esto evita que el mismo error reaparezca en una futura versión.

------------------------------------------------------------------------

# 4. Plan de Hotfix en menos de 30 minutos

        Tiempo Actividad
  ------------ ----------------------------------------------
      0--5 min Detectar, diagnosticar y registrar incidente
     5--10 min Crear `hotfix` y realizar corrección
    10--15 min Ejecutar pruebas automáticas
    15--20 min Build y despliegue Canary
    20--25 min Monitorear métricas
    25--30 min Ampliar despliegue o ejecutar rollback

### Condición importante

Este tiempo es un **objetivo operativo**, no una garantía. Para
acercarse a él, UrbanApp necesita automatizar previamente CI/CD,
pruebas, observabilidad y rollback.

------------------------------------------------------------------------

# 5. Despliegue Canary + Feature Flags

## ¿Qué es Canary Deployment?

Un Canary Deployment consiste en enviar una nueva versión solamente a
una pequeña parte de los usuarios antes de distribuirla a todos.

Ejemplo:

``` text
Versión estable 2.7.0
        │
        ├── 95% usuarios
        │
        └── 5% usuarios → API 2.8.0
```

Si la versión nueva funciona correctamente, se aumenta progresivamente:

``` text
5% → 25% → 50% → 100%
```

Si falla:

``` text
5% → Rollback
```

------------------------------------------------------------------------

# 6. Feature Flags

Los Feature Flags permiten activar o desactivar una funcionalidad sin
volver a desplegar todo el sistema.

Ejemplo:

``` javascript
if (featureFlags.newTripCompletion) {
    finalizarViajeV2();
} else {
    finalizarViajeV1();
}
```

Configuración:

``` json
{
  "newTripCompletion": false
}
```

Cuando la versión nueva se encuentre estable:

``` json
{
  "newTripCompletion": true
}
```

Esto permite desactivar rápidamente una función problemática.

------------------------------------------------------------------------

# 7. Solución combinada Canary + Feature Flags

La estrategia propuesta es:

``` mermaid
flowchart TD
    A[Nueva versión API] --> B[Feature Flag OFF]
    B --> C[Canary 5%]
    C --> D{Errores normales?}

    D -- No --> E[Desactivar Feature Flag]
    E --> F[Rollback]

    D -- Sí --> G[Feature Flag ON]
    G --> H[Canary 25%]

    H --> I{KPIs normales?}
    I -- No --> E
    I -- Sí --> J[Canary 50%]

    J --> K{KPIs normales?}
    K -- No --> E
    K -- Sí --> L[100% Producción]
```

## Ventajas

-   Reduce el impacto de errores.
-   Permite apagar funcionalidades rápidamente.
-   Evita realizar un nuevo despliegue para desactivar una
    característica.
-   Facilita pruebas con una cantidad limitada de usuarios.
-   Permite realizar un rollback de infraestructura y un rollback
    funcional por separado.

------------------------------------------------------------------------

# 8. Compatibilidad de API

El problema original se debe evitar utilizando **versionado y
retrocompatibilidad**.

## Ejemplo

En lugar de modificar directamente:

``` text
/api/v1/trips
```

se mantiene la versión anterior:

``` text
/api/v1/trips
```

y se introduce:

``` text
/api/v2/trips
```

Durante la transición:

``` text
App móvil antigua → API v1
App móvil actualizada → API v2
```

Después de comprobar que ya no existen clientes importantes utilizando
v1, se puede planificar su retiro.

------------------------------------------------------------------------

# 9. Regla de compatibilidad

Los cambios de API deben seguir una estrategia de evolución compatible.

### Evitar

``` json
{
  "driver": "Brian"
}
```

y cambiar directamente a:

``` json
{
  "driverName": "Brian",
  "driverId": 230308
}
```

porque una aplicación antigua puede depender de `driver`.

### Mejor

Mantener temporalmente:

``` json
{
  "driver": "Brian",
  "driverName": "Brian",
  "driverId": 230308
}
```

Después se puede retirar el campo antiguo mediante un proceso
controlado.

------------------------------------------------------------------------

# 10. Fases del SDLC y Despliegue Continuo

El flujo completo propuesto es:

``` mermaid
flowchart LR
    A[Planificación] --> B[Desarrollo]
    B --> C[Code Review]
    C --> D[CI]
    D --> E[Pruebas]
    E --> F[Build]
    F --> G[Staging]
    G --> H[Canary]
    H --> I[Producción]
    I --> J[Monitoreo]
    J --> K{Incidente?}
    K -- No --> L[Operación normal]
    K -- Sí --> M[Hotfix / Rollback]
    M --> D
```

## Fases

### 1. Planificación

Se define:

-   requisito
-   alcance
-   riesgos
-   criterios de aceptación

### 2. Desarrollo

El equipo trabaja mediante:

``` text
feature/*
```

### 3. Code Review

Todo cambio debe pasar por Pull Request.

### 4. Integración Continua

El pipeline ejecuta automáticamente:

``` text
Lint
↓
Unit Tests
↓
Integration Tests
↓
Contract Tests
↓
Security Checks
↓
Build
```

### 5. Staging

La versión se despliega en un ambiente similar a producción.

### 6. Canary

Se libera a un porcentaje reducido.

### 7. Producción

Se aumenta gradualmente hasta llegar al 100%.

### 8. Monitoreo

Se observan métricas y logs.

### 9. Feedback

Los resultados alimentan el siguiente ciclo de desarrollo.

------------------------------------------------------------------------

# 11. Pipeline CI/CD propuesto

Ejemplo conceptual:

``` yaml
name: UrbanApp CI/CD

on:
  push:
    branches:
      - develop
      - main
      - "hotfix/**"

jobs:

  test:
    runs-on: ubuntu-latest

    steps:
      - uses: actions/checkout@v4

      - name: Instalar dependencias
        run: npm ci

      - name: Tests unitarios
        run: npm test

      - name: Tests de contrato
        run: npm run test:contract

      - name: Tests de integración
        run: npm run test:integration

  build:
    needs: test
    runs-on: ubuntu-latest

    steps:
      - uses: actions/checkout@v4

      - name: Build
        run: docker build -t urbanapp-api:${{ github.sha }} .

      - name: Publicar artefacto
        run: echo "Publicar imagen en registry"

  deploy:
    needs: build
    runs-on: ubuntu-latest

    steps:
      - name: Deploy Staging
        run: echo "Deploy a staging"

      - name: Canary 5%
        run: echo "Deploy Canary"

      - name: Verificar métricas
        run: echo "Validar KPIs"

      - name: Promover
        run: echo "Promover versión"
```

> Este YAML es una representación académica del pipeline. Los comandos
> reales dependerán de la infraestructura utilizada por UrbanApp.

------------------------------------------------------------------------

# 12. Estrategia de Rollback

El rollback debe poder realizarse de forma automatizada.

## Ejemplo

Versión actual:

``` text
urbanapp-api:2.8.0
```

Versión estable anterior:

``` text
urbanapp-api:2.7.1
```

Si la nueva versión presenta errores:

``` text
2.8.0
  ↓
Rollback
  ↓
2.7.1
```

## Principio de despliegues reversibles

Cada versión debe conservar:

-   número de versión
-   imagen/artefacto
-   configuración
-   logs
-   fecha de despliegue
-   commit de Git

Esto permite identificar exactamente qué versión estaba funcionando.

------------------------------------------------------------------------

# 13. Migraciones de base de datos

Un rollback de código puede fallar si la base de datos fue modificada de
forma incompatible.

Por eso se recomienda:

``` text
Expand → Migrate → Contract
```

Ejemplo:

### Fase 1 --- Expand

Agregar el nuevo campo sin eliminar el anterior:

``` text
driver
driverName
```

### Fase 2 --- Migrate

La aplicación empieza a utilizar el nuevo campo.

### Fase 3 --- Contract

Cuando todas las versiones necesarias son compatibles, se elimina el
campo antiguo.

Esto evita que un rollback del backend deje de funcionar por una
modificación irreversible de la base de datos.

------------------------------------------------------------------------

# 14. Métricas DevOps / DORA

Para comprobar si el proceso realmente mejora, UrbanApp debe medir
cuatro indicadores principales.

## 1. Deployment Frequency

Mide con qué frecuencia se realizan despliegues exitosos.

``` text
Deployment Frequency =
despliegues exitosos / periodo
```

Ejemplo:

``` text
20 despliegues / mes
```

------------------------------------------------------------------------

## 2. Lead Time for Changes

Mide cuánto tiempo pasa desde que un cambio se confirma hasta que llega
a producción.

``` text
Commit
  ↓
Build
  ↓
Test
  ↓
Deploy
```

Ejemplo:

``` text
Commit: 10:00
Producción: 10:18

Lead Time = 18 minutos
```

------------------------------------------------------------------------

## 3. Change Failure Rate

Mide qué proporción de los despliegues genera una falla que requiere
intervención.

``` text
Change Failure Rate =
despliegues con fallo /
despliegues totales × 100
```

Ejemplo:

``` text
2 despliegues con fallo
20 despliegues totales

CFR = 10%
```

------------------------------------------------------------------------

## 4. Time to Restore Service

Mide cuánto tiempo tarda el equipo en recuperar el servicio después de
un incidente.

``` text
Incidente: 14:00
Servicio restaurado: 14:18

TTRS = 18 minutos
```

------------------------------------------------------------------------

# 15. Tablero de KPIs

  -----------------------------------------------------------------------
  KPI                                 Objetivo operativo
  ----------------------------------- -----------------------------------
  Deployment Frequency                Aumentar gradualmente la frecuencia
                                      de despliegues seguros

  Lead Time for Changes               Reducir el tiempo entre commit y
                                      producción

  Change Failure Rate                 Reducir la cantidad de despliegues
                                      que provocan incidentes

  Time to Restore Service             Restaurar incidentes críticos en
                                      menos de 30 minutos

  HTTP 5xx                            Mantenerlo dentro del umbral
                                      definido por el SLO

  Latencia API                        Mantenerla dentro del SLO

  Error de finalización de viajes     Mantenerlo cercano a cero
  -----------------------------------------------------------------------

> Los objetivos numéricos definitivos deben establecerse con datos
> históricos de UrbanApp y sus SLOs, en lugar de elegir valores
> arbitrarios.

------------------------------------------------------------------------

# 16. Plan de prevención

Para evitar que el incidente vuelva a ocurrir:

### API

-   Versionar endpoints.
-   Mantener compatibilidad hacia atrás.
-   Utilizar pruebas de contrato.
-   Documentar cambios.
-   Aplicar políticas de deprecación.

### Desarrollo

-   Pull Requests obligatorios.
-   Code Review.
-   CI automático.
-   Pruebas unitarias e integración.
-   Pruebas de contrato entre Mobile y Backend.

### Infraestructura

-   Artefactos inmutables.
-   Despliegues Canary.
-   Rollback automatizado.
-   Staging similar a producción.

### Operación

-   Logs centralizados.
-   Métricas.
-   Alertas.
-   Dashboards.
-   Trazabilidad de despliegues.

### Funcionalidades

-   Feature Flags.
-   Activación gradual.
-   Kill switch para funciones críticas.

------------------------------------------------------------------------

# 17. Flujo final de trabajo

``` mermaid
flowchart TD
    A[Requisito] --> B[Feature Branch]
    B --> C[Pull Request]
    C --> D[Code Review]
    D --> E[CI]
    E --> F[Tests]
    F --> G[Build]
    G --> H[Staging]
    H --> I[Canary 5%]
    I --> J{¿Sin errores?}

    J -- No --> K[Feature Flag OFF]
    K --> L[Rollback]
    L --> M[Hotfix]

    J -- Sí --> N[25%]
    N --> O{¿Sin errores?}

    O -- No --> K
    O -- Sí --> P[50%]

    P --> Q{¿Sin errores?}

    Q -- No --> K
    Q -- Sí --> R[100%]

    R --> S[Monitoreo]
    S --> T[DORA Metrics]
```

------------------------------------------------------------------------

# 18. Resultado esperado

Con esta estrategia, UrbanApp pasa de un modelo de despliegue riesgoso:

``` text
Desarrollo
    ↓
Producción 100%
    ↓
Error
    ↓
Rollback manual
```

a un proceso controlado:

``` text
Desarrollo
    ↓
CI/CD
    ↓
Pruebas
    ↓
Staging
    ↓
Canary 5%
    ↓
Canary 25%
    ↓
Canary 50%
    ↓
100%
    ↓
Monitoreo
```

Si ocurre un incidente:

``` text
Alerta
   ↓
Feature Flag OFF
   ↓
Rollback
   ↓
Hotfix
   ↓
Pruebas
   ↓
Canary
   ↓
Producción
```

## Conclusión

La solución para UrbanApp no consiste únicamente en hacer un rollback.
El problema principal es de **gestión del ciclo de vida del software y
coordinación entre Mobile, Backend y Operaciones**.

La propuesta combina:

-   **GitFlow** para controlar cambios y hotfixes.
-   **CI/CD** para automatizar pruebas y despliegues.
-   **Versionado de API** para mantener compatibilidad con aplicaciones
    móviles anteriores.
-   **Canary Deployment** para reducir el impacto de una nueva versión.
-   **Feature Flags** para activar o desactivar funcionalidades
    rápidamente.
-   **Rollback automatizado** para recuperar una versión estable.
-   **Migraciones compatibles** para evitar problemas con la base de
    datos.
-   **Métricas DORA** para medir objetivamente la evolución del proceso.

El objetivo final es que una falla crítica pueda detectarse, contenerse
y recuperarse rápidamente sin detener el desarrollo de nuevas versiones.
