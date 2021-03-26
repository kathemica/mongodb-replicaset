'use strict';
import { createRequire } from 'module';
const require = createRequire(import.meta.url);
const MongoClient = require('mongodb').MongoClient;
require('dotenv').config();

import fs from 'fs';
import colors from 'colors';
import cliProgress from 'cli-progress';
const _progress = require('cli-progress');

// import { NODE_ENVIRONMENT } from './config/config.js';
import { randomInt, random, sleep } from './assets/supportFunctions.js'

// console.log(`NODE_ENV=${NODE_ENVIRONMENT}`);

const main = async () => {      
  
  // console.log(process.env);
  
  const ca = [fs.readFileSync(process.env.CA_CERT)];    
  const key = fs.readFileSync(process.env.KEY_CERT);
  const cert = fs.readFileSync(process.env.PEM_CERT);
  const sslPass = process.env.CA_TOKEN;
  const replicaSet= process.env.REPLICASET;
  const serverName= process.env.HOST;
  const port= process.env.SERVICE_PORT;
  const authMechanism= process.env.AUTHMECANISM;    
  const readPreference = process.env.READPREFERENCE;
  const isSSL = process.env.USE_SSL;
  
     const url = `mongodb://10.0.0.12:27017/?authMechanism=MONGODB-X509&replicaSet=my-replica-set&readPreference=primary&authSource=%24external&appname=MongoDB%20Compass&ssl=true&authSource=$external`;
  // const url = `mongodb://${serverName}:${port}/?authMechanism=${authMechanism}&replicaSet=${replicaSet}&readPreference=${readPreference}&authSource=%24external&appname=mongodbReplicaset&ssl=${isSSL}`;

  let options = {           
      useNewUrlParser: true,
      poolSize: 15,                        
      ssl: true,
      sslValidate: false,
      sslCA: ca,
      sslKey: key,
      sslCert: cert,
      sslPass,
      tlsAllowInvalidHostnames: true,
      useUnifiedTopology: true
  };
  
  try{    
    console.clear();
    console.log(`${'Creating connection'.green}\n` );         
    const client= MongoClient.connect(url, options);
    console.log(`${'\nIn progress...'.blue} \nAwaiting for being connected and start the process\n`)
    
    const db = (await client).db('iot');    
    db ? console.log(`${'Connected'.green} to DB ${'IoT'.yellow}\nMessage: Trying to populate data in ${'devices'.blue} collation.\n` ) : new error("Error con la base de datos");
    
    const MAX_INTERATIONS = process.env.MAX_INTERATIONS;
    
    console.log(`Populating ${MAX_INTERATIONS} devices, be patient.\n`)
    
    // const progressBar = new cliProgress.SingleBar({}, cliProgress.Presets.shades_classic);
    const progressBar = new _progress.Bar({
        // blue bar, reset styles after bar element
        format: 'progress [\u001b[34m{bar}\u001b[0m] {percentage}% | ETA: {eta}s | {value}/{total} | Sensor ID: {speed}',
        hideCursor: true,
        barCompleteChar: '\u2588',
        barIncompleteChar: '\u2591',
        barGlue: '\u001b[33m' //green
    });
    progressBar.start(MAX_INTERATIONS, 0, {
      speed: "N/A"
    });

    for (let i=0; i<MAX_INTERATIONS; i++) {                  
      await updateDocument(db,i);
      // update the current value in your application..
      progressBar.update(i+1, {
        speed: (1029384756+i).toString()
      });
    }

    // stop the progress bar
    progressBar.stop();

    console.log(`\n${'That\'s it,'.blue} Good bye!!\n\n\n`)
    console.log(`${'Thank you for using my software'.green} Eng. Katherine Aguirre !!\n`)
    process.exit();                                    
  }catch(e){
      console.log(`${'SOMETHING WENT WRONG'.red} we're in trouble, I got this: ${e}\n`);  
      console.log(`${'Closing app...'.blue} Good bye!!\n` )
      process.exit();      
  }    
}

main();

// Upsert IoT documents
const updateDocument = async(db,i) => {
  try{
    const collection = db.collection('devices');
    const deviceId = 1029384756+i;
    const temperature = random(-10,50);
    const humidity = randomInt(0,100);
    const date = new Date();
  
    // Create document
    const doc = {
      deviceId: deviceId,
      sensorType: "SensorHT",
      telemetry: {
        temperature:{
          timestamp: date,
          value: temperature
        },
        humidity:{
          timestamp: date,
          value: humidity
        }         
      },
      date: {
        year: date.getFullYear(),
        month: date.getMonth(),
        day: date.getDate(),
        hour: date.getHours()
      }
    };
  
    // Upsert document (bucket/hour)
    await collection.updateOne({
      deviceId: doc.deviceId,
      "date.year": doc.date.year,
      "date.month": doc.date.month,
      "date.day": doc.date.day,
      "date.hour": doc.date.hour,
      sensor: doc.sensorType,
      nsamples: {$lt: 200}
    },{
      $inc: {nsamples: 1},
      $set: {
        deviceId: doc.deviceId,
        "date.year": doc.date.year,
        "date.month": doc.date.month,
        "date.day": doc.date.day,
        "date.hour": doc.date.hour,
        sensor: doc.sensorType
      },
      $addToSet: {lectures: doc.telemetry}
    },{
      upsert: true, returnNewDocument: true
    }); 

    // console.log(`Device: ${deviceId}`);
  }catch(e){
    throw new Error(`${'...Something went wrong, here the details: '.red}`, e)
  }           
}
