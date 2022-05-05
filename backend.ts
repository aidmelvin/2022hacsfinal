
import express, { Request, Response } from "express";
import cors from "cors";

const app = express();

let corsOptions = {
    origin : '*',
    methods: ['GET', 'POST', 'PUT', 'DELETE'],
    allowedHeaders: ['Content-Type']
}

app.use(cors(corsOptions));

export type RouteHandler = (request: Request, response: Response) => void;

const loginHandler: RouteHandler = (req, res) => {
  let body: string = "";
  let parsedBody: JSON;

  req.on('data', (chunk) => {
    body += chunk;
  });
  req.on('end', () => {
    parsedBody = JSON.parse(body);
    console.log('POSTed: ' + body);
    res.send('{"message": "received the get request"}');
  })
    //console.log(req);
}

app.get("/", (req, res) => {
    res.sendFile("index.html", {root: '.'});
});

/*
 * Serve static files within the static/ directory.
 */
app.get("/static/*", (req, res) => {
    console.log(`serving static file: ${req.path}`)
    res.sendFile(req.path, {root: "."});
});

app.post('/login', loginHandler);

app.listen(5000);

console.log("listening on port 5000");
