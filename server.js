const http = require("http");
const bodyParser = require('body-parser');
const app = require("express")();
const EventEmitter = require("events");

const server = http.createServer(app);
server.listen(3000, () => console.log(`Paths livestream server is now running on port ${server.address().port}!`));

const io = require("socket.io")(server);

const emitter = new EventEmitter();
emitter.on("attempt_connection", (stream) => console.log("New user attempted to connect to Paths livestream server!"));

app.use(bodyParser.urlencoded({ extended: false }));

app.get("/", (request, response) => {
  const error = {
    "status": "error",
    "reason": "Please connect to a socket.io room in order to use Paths livestream service."
  }
  response.header("Content-Type", "application/json")
  response.send(JSON.stringify(error));
  emitter.emit("attempt_connection");
});
