

// Versión estable de la API
function apiEstable(id) {
  return {
    version: "estable",
    tripId: id,
    status: "finished"
  };
}

// Nueva versión de la API
function apiNueva(id) {

  // Simulamos un 20% de probabilidad de error
  if (Math.random() < 0.20) {
    throw new Error("Error crítico al finalizar el viaje");
  }

  return {
    version: "nueva",
    id: id,
    trip_status: "completed"
  };
}

// Feature Flag
const featureFlags = {
  newTripApi: true
};

// Porcentaje inicial del Canary
const CANARY_PERCENTAGE = 5;

// Decide si un usuario entra al Canary
function usarCanary() {
  const numeroAleatorio = Math.random() * 100;

  return numeroAleatorio < CANARY_PERCENTAGE;
}

// Decide qué versión usar
function finalizarViaje(id) {

  if (featureFlags.newTripApi && usarCanary()) {
    return apiNueva(id);
  }

  return apiEstable(id);
}

// Contadores
let estable = 0;
let nueva = 0;
let errores = 0;

// Simulación de 1000 usuarios
for (let i = 1; i <= 1000; i++) {

  try {

    const resultado = finalizarViaje(i);

    if (resultado.version === "nueva") {
      nueva++;
    } else {
      estable++;
    }

  } catch (error) {

    errores++;

  }
}

// Resultados
console.log("----------------------------------");
console.log(" CANARY DEPLOYMENT - URBANOAPP");
console.log("----------------------------------");

console.log(`Feature Flag: ${
  featureFlags.newTripApi ? "ACTIVADO" : "DESACTIVADO"
}`);

console.log(`Canary configurado: ${CANARY_PERCENTAGE}%`);

console.log("----------------------------------");

console.log("Usuarios API estable:", estable);
console.log("Usuarios API nueva:", nueva);
console.log("Errores detectados:", errores);

console.log("----------------------------------");