var http = require('http');
var connect = require('connect');
var fs = require('fs');
var path = require('path');
var jit = require('express-jit-coffee');
var opra = require('opra');

var args = process.argv.slice(2);
var ports = args.map(function(x) { return parseInt(x, 10); }).filter(function(x) { return x; }).concat([7000]);
var dirs = args.filter(function(x) { return isNaN(parseInt(x, 10)); }).concat(['.']);

var port = ports[0];
var dir = path.resolve(process.cwd(), dirs[0]);

var rome = function(req, res, next) {
  if (req.headers.accept.indexOf('text/html') != -1) {
    req.url = "/index.html";
  }
  next();
};

var app = connect().use(opra.serve(dir)).use(jit(dir)).use(connect.static(dir)).use(rome).use(opra.serve(dir));


http.createServer(app).listen(port);
console.log("Serving " + dir + " at port " + port);