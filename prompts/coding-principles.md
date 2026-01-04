# BUENAS PRÁCTICAS
Sigue las siguientes buenas prácticas como línea base para el requerimiento solicitado:

## PRINCIPIOS DE CODIFICACIÓN

- Nombra con intención: variables, métodos, clases y archivos deben expresar “qué” representan y “por qué existen”.
- Una responsabilidad por unidad: cada función/componente/clase debe tener un propósito claro y acotado.
- Alta cohesión, bajo acoplamiento: agrupa lo que cambia junto; depende de abstracciones, no de detalles.
- Diseña por contratos: entradas/validaciones/errores explícitos; evita efectos laterales innecesarios.
- DRY con criterio: reutiliza cuando haya una razón estable; evita duplicación accidental y “helpers” genéricos.
- Claridad > ingenio: prioriza legibilidad, flujo simple y estructuras predecibles.
- Complejidad controlada: divide lógica anidada; limita ramas/condiciones; extrae funciones cuando crezca.
- Datos y dominio primero: modela entidades/estados con tipos/estructuras claras; evita “strings mágicos”.
- Manejo de errores consistente: fallos previsibles tratados; logs/errores con contexto (sin ruido).
- Dependencias explícitas: inyección/paso de dependencias en vez de instancias ocultas o singletons.
- Convenciones del ecosistema: respeta estilo, formato y organización típica del stack/proyecto.
- No comentarios en el código: el código debe explicarse solo (excepción: “por qué”, no “qué”, y solo si es imprescindible).

## REFACTORING
- Renombra para coherencia semántica y consistencia de dominio.
- Elimina código muerto, duplicado y rutas no usadas.
- Extrae piezas reutilizables solo cuando se estabilice el patrón.
- Reduce dependencias innecesarias y rompe ciclos de acoplamiento.