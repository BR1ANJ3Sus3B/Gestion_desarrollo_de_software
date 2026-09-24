import express from "express"

const app = express();

app.use(express.json());

app.post("/trips/:id/finish", (req, res) => {
  const id = req.params.id;

  res.json({
    tripId: id,
    status: "finished",

    id: id,
    trip_status: "completed"
  });
});

app.listen(3000, () => {
  console.log("UrbanoApp API ejecutándose en http://localhost:3000");
});