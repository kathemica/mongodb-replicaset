'use strict';
import { createRequire } from 'module';
const require = createRequire(import.meta.url);
const MongoClient = require('mongodb').MongoClient;
require('dotenv').config();

import fs from 'fs';
import colors from 'colors';
import _progress from 'cli-progress';
import { randomInt, random} from './assets/supportFunctions.js'

const main = async () => {   
  const pEnv = process.env;       
  const ca = [fs.readFileSync(pEnv.CA_CERT)];    
  const key = fs.readFileSync(pEnv.KEY_CERT);
  const cert = fs.readFileSync(pEnv.PEM_CERT);  
      
  const url = `mongodb://${pEnv.HOST}:${pEnv.SERVICE_PORT}/?authMechanism=${pEnv.AUTHMECANISM}&replicaSet=${pEnv.REPLICASET}&readPreference=${pEnv.READPREFERENCE}&authSource=%24external&appname=mongodbReplicaset&ssl=${JSON.parse(pEnv.USE_SSL.toLowerCase())}`;

  let options = {           
      useNewUrlParser: true,
      poolSize: 15,                        
      ssl: JSON.parse(pEnv.USE_SSL.toLowerCase()),
      sslValidate: false,
      sslCA: ca,
      sslKey: key,
      sslCert: cert,
      sslPass: pEnv.CA_TOKEN,
      tlsAllowInvalidHostnames: true,
      useUnifiedTopology: true
  };
  
  try{    
    console.clear();

    console.log(`${'Creando la conexión'.green}\n` );         
    const client= MongoClient.connect(url, options);
    console.log(`${'\nEn progreso...'.blue} \nEsperando por la conexión para iniciar el proceso.\n`)
    
    const db = (await client).db('iot');    
    db ? console.log(`${'Conectada'.green} to DB ${'IoT'.cyan}\nMensaje: Tratando de popular la data en la coleccipon ${'devices'.blue} .\n` ) : new error("Error con la base de datos");
    
    const MAX_INTERATIONS = pEnv.MAX_INTERATIONS;
    
    console.log(`Cargando ${MAX_INTERATIONS} dispositivos, se paciente.\n`)
      
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

    console.log(`\n${'Listo!!,'.blue} Good bye!!\n\n\n`);
    console.log(`${'Gracias por usar mi aplicación'.green} Ing. Katherine Aguirre !!\n`);

    process.exit();            

  }catch(e){
      console.log(`${'OH OH, algo no va bien!!!!'.red}, obtuve ésto: ${e}\n`);  
      console.log(`${'Cerrando la app...'.blue} lo lamento!!\n` );
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
    
  }catch(e){
    throw new Error(`${'...te muestro: '.red}`, e)
  }           
}
