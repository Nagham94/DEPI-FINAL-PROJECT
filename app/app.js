const path = require('path');
const fs = require('fs');
const express = require('express');
const OS = require('os');
const bodyParser = require('body-parser');
const mongoose = require('mongoose');
const app = express();
const cors = require('cors');
const serverless = require('serverless-http');

app.use(bodyParser.json());
app.use(express.static(path.join(__dirname, '/')));
app.use(cors());

// Connect to MongoDB
const mongoOptions = {
    useNewUrlParser: true,
    useUnifiedTopology: true,
};

if (process.env.MONGO_USERNAME && process.env.MONGO_PASSWORD) {
    mongoOptions.user = process.env.MONGO_USERNAME;
    mongoOptions.pass = process.env.MONGO_PASSWORD;
}

mongoose.connect(process.env.MONGO_URI, mongoOptions, function(err) {
    if (err) {
        console.log("Error connecting to MongoDB: " + err);
    } else {
        console.log("MongoDB Connection Successful");
    }
});

// Define Mongoose Schema
const Schema = mongoose.Schema;

const dataSchema = new Schema({
    name: String,
    id: Number,
    description: String,
    image: String,
    velocity: String,
    distance: String
});

const planetModel = mongoose.model('planets', dataSchema);

// Routes
app.post('/planet', function(req, res) {
    planetModel.findOne({ id: req.body.id }, function(err, planetData) {
        if (err || !planetData) {
            console.error("Error or no planet found for ID:", req.body.id);
            res.status(404).send("Ooops, We only have 9 planets and a sun. Select a number from 0 - 9");
        } else {
            res.send(planetData);
        }
    });
});

app.get('/', async (req, res) => {
    res.sendFile(path.join(__dirname, '/', 'index.html'));
});

app.get('/api-docs', (req, res) => {
    fs.readFile('oas.json', 'utf8', (err, data) => {
        if (err) {
            console.error('Error reading file:', err);
            res.status(500).send('Error reading file');
        } else {
            res.json(JSON.parse(data));
        }
    });
});

app.get('/os', function(req, res) {
    res.setHeader('Content-Type', 'application/json');
    res.send({
        "os": OS.hostname(),
        "env": process.env.NODE_ENV
    });
});

app.get('/live', function(req, res) {
    res.setHeader('Content-Type', 'application/json');
    res.send({
        "status": "live"
    });
});

app.get('/ready', function(req, res) {
    res.setHeader('Content-Type', 'application/json');
    res.send({
        "status": "ready"
    });
});

// Start Server
app.listen(3000, () => {
    console.log("Server successfully running on port - 3000");
});

module.exports = app;
// module.exports.handler = serverless(app);
