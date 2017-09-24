const http = require("http");
const bodyParser = require('body-parser');
const app = require("express")();
const EventEmitter = require("events");
const util = require('util');
const process = require('child_process');

const server = http.createServer(app);
server.listen(3000, () => console.log(`Paths livestream server is now running on port ${server.address().port}!`));

const io = require("socket.io")(server);

const emitter = new EventEmitter();
emitter.on("attempt_connection", (stream) => console.log("A user attempted to connect to Paths livestream server!"));

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

io.on("connection", (socket) => {
  console.log("A user successfully connected to Paths livestream server!")

  socket.on("create", (room) => {
    socket.join(room.key);
  });

  socket.on("stream_started", (stream) => {
    const secretKey = stream.key;
    const executeCommand = util.promisify(process.exec);

    console.log(`Stream started - secret key is ${secretKey}`);

    async function startSnapshot() {
      const { output, error } = await executeCommand(`ffmpeg -i rtmp://35.202.142.142:1935/stream/${secretKey} -f image2 -vf fps=fps=1/5 snapshot-${secretKey}-%d.png`);
      console.log(`Output parsed: ${output}`);
      console.log(`Error occured: ${error}`);
    }
    startSnapshot();
  });

  socket.on("location_update", (stream) => {
    const latitude = stream.latitude;
    const longitude = stream.longitude;
    console.log(`Received data - Latitude: ${latitude} - Longitude: ${longitude}`)
  });

  socket.on("disconnect", () => {
    const executeCommand = util.promisify(process.exec);
    console.log("A user disconnected from Paths livestream server!");

    async function endSnapshot() {
      const { output, error } = await executeCommand("sudo killall ffmpeg");
      console.log(`Output parsed: ${output}`);
      console.log(`Error occured: ${error}`);
    }
    endSnapshot();
  });
});
