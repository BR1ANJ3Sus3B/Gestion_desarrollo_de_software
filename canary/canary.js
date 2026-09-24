function apiEstable(id) {
  return {
    tripId: id,
    status: "finished"
  };
}

function apiNueva(id) {
  return {
    id: id,
    trip_status: "completed"
  };
}
const featureFlags = {
  newTripApi: true
};

const CANARY_PERCENTAGE = 5;