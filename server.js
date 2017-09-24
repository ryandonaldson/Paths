const http = require("http");
const bodyParser = require('body-parser');
const app = require("express")();
const EventEmitter = require("events");
const util = require('util');
const process = require('child_process');
const fs = require("fs");
const glob = require("glob")

const gcloud = require('gcloud')({
  keyFilename: '/home/legit_youtb56/Paths/Paths-Livestream-362df505f5ad.json',
  projectId: '362df505f5ade3f61ae9b9845837c41f3ca5d4cb'
});

const vision = gcloud.vision();

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
    console.log(`Stream started - secret key is ${secretKey}`);

    const executeCommand = util.promisify(process.exec);
    async function takeSnapshot() {
      const { output, error } = await executeCommand(`ffmpeg -i rtmp://35.202.142.142:1935/stream/${secretKey} -f image2 -vf fps=fps=1/5 snapshot-${secretKey}-%d.png`);
      console.log(`Output parsed: ${output}`);
      console.log(`Error occured: ${error}`);
    }
    takeSnapshot();
  });

  socket.on("location_update", (stream) => {
    const executeCommand = util.promisify(process.exec);

    const secretKey = stream.key;
    const latitude = stream.latitude;
    const longitude = stream.longitude;

    console.log(`Received data - Latitude: ${latitude} - Longitude: ${longitude} `);
  });

  socket.on("recent_snapshot", (stream) => {
    let secretKey = stream.key;
    fs.readdir("/home/legit_youtb56/Paths/", function(err, files) {
      if (!err) {
        var out = [];
        files.forEach(function(file) {
            var stats = fs.statSync("/home/legit_youtb56/Paths/" + file);
            if (stats.isFile()) {
                out.push({"file": file, "mtime": stats.mtime.getTime()});
            }
        });
        out.sort(function(a, b) {
            return b.mtime - a.mtime;
        })
        const file = (out.length > 0) ? out[0].file : "";

        const options = {
          verbose: true
        };

        vision.detectLabels(file, options, function(err, detections, apiResponse) {
          if (err) {
            res.end('Cloud Vision Error');
            console.log("An error occured while attempting to upload to Cloud Vision!")
          } else {
            let finalJson = JSON.stringify(detections, null, 4);
            console.log(`We detected a ${finalJson[0]} near you!``);
          }
        });

        console.log(file);
      }
    });
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
