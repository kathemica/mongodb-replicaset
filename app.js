'use strict';
import { createRequire } from 'module';
const require = createRequire(import.meta.url);
const MongoClient = require('mongodb').MongoClient;
require('dotenv').config();

import fs from 'fs';
import colors from 'colors';
// import dotenv from 'dotenv';
// import { NODE_ENVIRONMENT } from './config/config.js';
import { randomInt, random, sleep } from './assets/supportFunctions.js'

// console.log(`NODE_ENV=${NODE_ENVIRONMENT}`);

const main = async () => {      
  console.clear();
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

  const url = `mongodb://${serverName}:${port}/?authMechanism=${authMechanism}&replicaSet=${replicaSet}&readPreference=${readPreference}&authSource=%24external&appname=mongodbReplicaset&ssl=${isSSL}`;

  let options = {           
      useNewUrlParser: true,
      poolSize: 15,                        
      ssl: isSSL,
      sslValidate: false,
      sslCA: ca,
      sslKey: key,
      sslCert: cert,
      sslPass,
      tlsAllowInvalidHostnames: true,
      useUnifiedTopology: true
  };
  
  try{
      const client= MongoClient.connect(url, options);
      console.log(`${'In progress...'.blue} \nAwaiting for being connected and start the process\n`);  
      client.then((result) => {
        console.log(`${'Connected'.green} \nMessage: Let's get started!!\n` );          
        const db = result.db(iot);

        for (let i=0; i<100; i++) {            
            updateDocument(db,i);
        }
      }).catch((error) => {
          console.log(`${'SOMETHING WENT WRONG'.red} we're in trouble, I got this: ${error}\n`);        
      }).finally(() => {
          console.log(`${'Closing all...'.blue} Good bye!!\n` )
          process.exit();
        }        
      )                                 
  }catch(e){
      console.log(`${'ERROR'.red} we're in trouble, I got this: ${e}\n`);        
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

    console.log(`Device: ${deviceId}`);
  }catch(e){
    throw new Error(`${'...Something went wrong, here the details: '.red}`, e)
  }           
}
