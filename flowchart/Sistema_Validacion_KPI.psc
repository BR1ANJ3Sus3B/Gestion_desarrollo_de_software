Algoritmo Sistema_Validacion_KPI
	Definir intentos, i Como Entero
	Definir cantidad, precio, total Como Real
	Definir errores, operacionesCorrectas, operacionesConError Como Entero
	Definir erroresCorregidos Como Entero
	Definir porcentajeErrores, porcentajeCorrectas, tasaCorreccion Como Real
	Definir errorDetectado, corregido Como Lógico
	Definir respuesta Como Cadena
	// Inicialización de indicadores
	errores <- 0
	operacionesCorrectas <- 0
	operacionesConError <- 0
	erroresCorregidos <- 0
	Escribir '============================================'
	Escribir '    SISTEMA DE VALIDACION EMPRESARIAL'
	Escribir '============================================'
	Escribir ''
	Escribir '¿Cuantas operaciones desea realizar?'
	Leer intentos
	// Validar que el número de intentos sea válido
	Mientras intentos<=0 Hacer
		Escribir 'Error: debe ingresar un numero mayor que 0.'
		Escribir 'Ingrese nuevamente el numero de operaciones:'
		Leer intentos
	FinMientras
	// Procesamiento de las operaciones
	Para i<-1 Hasta intentos Hacer
		errorDetectado <- Falso
		corregido <- Falso
		Escribir ''
		Escribir '--------------------------------------------'
		Escribir 'OPERACION ', i, ' DE ', intentos
		Escribir '--------------------------------------------'
		Escribir 'Ingrese la cantidad del producto:'
		Leer cantidad
		Escribir 'Ingrese el precio del producto:'
		Leer precio
		// Validar cantidad
		Si cantidad<=0 Entonces
			errorDetectado <- Verdadero
			errores <- errores+1
			Escribir ''
			Escribir '***** ERROR DETECTADO *****'
			Escribir 'La cantidad ingresada no es valida.'
			Escribir 'Accion recomendada: verificar y corregir el dato.'
		FinSi
		// Validar precio
		Si precio<=0 Entonces
			errorDetectado <- Verdadero
			errores <- errores+1
			Escribir ''
			Escribir '***** ERROR DETECTADO *****'
			Escribir 'El precio ingresado no es valido.'
			Escribir 'Accion recomendada: verificar el precio registrado.'
		FinSi
		// Evaluar resultado de la operación
		Si errorDetectado=Verdadero Entonces
			operacionesConError <- operacionesConError+1
			Escribir ''
			Escribir '--------------------------------------------'
			Escribir 'PROCESO DETENIDO'
			Escribir 'La operacion contiene datos incorrectos.'
			Escribir '--------------------------------------------'
			// Preguntar si el usuario desea corregir
			Escribir ''
			Escribir '¿Desea corregir los datos? (S/N)'
			Leer respuesta
			Si respuesta='S' O respuesta='s' Entonces
				Escribir ''
				Escribir 'Ingrese nuevamente la cantidad:'
				Leer cantidad
				Escribir 'Ingrese nuevamente el precio:'
				Leer precio
				// Comprobar si los datos corregidos son válidos
				Si cantidad>0 Y precio>0 Entonces
					corregido <- Verdadero
					erroresCorregidos <- erroresCorregidos+1
					Escribir ''
					Escribir 'CORRECCION EXITOSA'
					Escribir 'Los datos han sido validados correctamente.'
					total <- cantidad*precio
					Escribir 'Total de la operacion: $', total
				SiNo
					Escribir ''
					Escribir 'ERROR: Los datos corregidos siguen siendo invalidos.'
					Escribir 'La operacion no puede continuar.'
				FinSi
			FinSi
		SiNo
			operacionesCorrectas <- operacionesCorrectas+1
			total <- cantidad*precio
			Escribir ''
			Escribir 'VALIDACION COMPLETADA'
			Escribir 'No se detectaron errores.'
			Escribir 'Total de la operacion: $', total
		FinSi
	FinPara
	// ============================================
	// CALCULO DE INDICADORES CLAVE DE RENDIMIENTO
	// ============================================
	porcentajeErrores <- (operacionesConError/intentos)*100
	porcentajeCorrectas <- (operacionesCorrectas/intentos)*100
	Si operacionesConError>0 Entonces
		tasaCorreccion <- (erroresCorregidos/operacionesConError)*100
	SiNo
		tasaCorreccion <- 0
	FinSi
	// ============================================
	// REPORTE FINAL
	// ============================================
	Escribir ''
	Escribir ''
	Escribir '============================================'
	Escribir '          REPORTE DE RENDIMIENTO'
	Escribir '============================================'
	Escribir 'Total de operaciones: ', intentos
	Escribir 'Operaciones correctas: ', operacionesCorrectas
	Escribir 'Operaciones con error: ', operacionesConError
	Escribir 'Errores detectados: ', errores
	Escribir 'Errores corregidos: ', erroresCorregidos
	Escribir ''
	Escribir '----------- INDICADORES KPI -----------'
	Escribir 'Tasa de errores detectados: ', porcentajeErrores, '%'
	Escribir 'Tasa de operaciones correctas: ', porcentajeCorrectas, '%'
	Escribir 'Tasa de correccion de errores: ', tasaCorreccion, '%'
	Escribir '============================================'
	// Interpretación general
	Escribir ''
	Escribir '----------- EVALUACION DEL SISTEMA -----------'
	Si porcentajeCorrectas>=90 Entonces
		Escribir 'Alto porcentaje de operaciones correctas.'
	SiNo
		Si porcentajeCorrectas>=70 Entonces
			Escribir 'El sistema presenta un nivel medio de operaciones correctas.'
		SiNo
			Escribir 'Se recomienda revisar el proceso de captura y validacion de datos.'
		FinSi
	FinSi
	Si porcentajeErrores>30 Entonces
		Escribir 'ALERTA: Se detecto una cantidad elevada de operaciones con errores.'
	FinSi
	Escribir ''
	Escribir 'Proceso de evaluacion finalizado.'
FinAlgoritmo
