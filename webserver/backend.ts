
import express, { Request, Response } from "express";
import cors from "cors";

const app = express();

let corsOptions = {
    origin : '*',
    methods: ['GET', 'POST', 'PUT', 'DELETE'],
    allowedHeaders: ['Content-Type']
}

app.use(cors(corsOptions));

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

app.post('/login', (req, res) => {
    console.log("received  post request");
    res.redirect("/incorrect");
});

app.get("/incorrect", (req, res) => {
    console.log('redirected');
    res.sendFile("incorrect.html", {root: '.'});
});

app.listen(5000);

console.log("listening on port 5000");