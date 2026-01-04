# SOLICITUD

Te proporcionaré el código fuente web de mi aplicación a fin de analizarlo exhaustivamente para brindar solución a los siguientes requerimientos:

- Gestión de gastos (Actualición y nuevo gasto - verificación de límite)
  - Se ha actualizado la respuesta de los servicios backend `ExpenseUpdateService` y `ExpenseSaveService` para que retornen `ExpenseUpdateResponseDto` y `ExpenseSaveResponseDto` respectivamente, en las cuales está incluido el campo isBelowLimit.
  - La razón del cambio es que si isBelowLimit es false, entonces hay que mostrar un mensaje de warning indicando que se superó el límite mensual para la categoría seleccionada.
  - Este mensaje de warning no debe cerrarse automáticamente, sino es el usuario es quien debe hacerlo.
  - En este sentido, hay que actualizar la UI, que actualmente espera recibir solamente un booleano (para la actualización) y un string (uuid para el guardado), pero ahora tendrá que recibir los objetos Dto para aplicar este comportamiento.

Bríndame el código fuente de todos los componentes en un archivo .zip con los archivos modificados/añadidos.
