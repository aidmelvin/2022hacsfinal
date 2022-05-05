"use strict";
exports.__esModule = true;
var express = require("express");
var app = express();
app.get("/login", function (request, response) {
    response.send("Login Information Incorrect");
});
app.listen(5000);
