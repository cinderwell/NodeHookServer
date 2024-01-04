const express = require('express');
const bodyParser = require('body-parser');
const fs= require('fs');
const path = require('path');
const https = require('https');
const sqlite3 = require('sqlite3');
const API = require('./apiAuth');

const app = express();
app.use(bodyParser.urlencoded({ extended: false }));
app.use(bodyParser.json());

const db = new sqlite3.Database('C:/Projects/NodeHookServer/jobs.db');

//const bee = 'Start-Job { C:/Projects/NodeHookServer/WorkerBee.ps1'
const bee = 'Start-Job -filepath "C:/Projects/NodeHookServer/WorkerBee.ps1" -ArgumentList'
const terminator = 'Start-Job -filepath "C:/Projects/NodeHookServer/Terminator.ps1" -ArgumentList'

const { PowerShell } = require('node-powershell');

//initialize a shell instance
const ps = new PowerShell({
    executionPolicy: 'Bypass',
    noProfile: true
});



//catch-up on missed new hire jobs on server startup
ps.invoke('Start-Job -filepath "C:/Projects/NodeHookServer/WorkerBeeCatchup.ps1"');

//when POST on newemployee API (no longer using this, triggers too late)
app.post('/api/newemployee', API.authenticateKey, (req, res) => {
  
  res.status(200).send({
    data: 'accepted',
  });

  console.log("New Employee API:");
  console.log(req);
  /*
  let new_emp_id = parseInt(req.body.Object_Identifier);

  console.log(new_emp_id);

  let sql = 'INSERT INTO new_employees VALUES(?,?,?,?)';
  let date = new Date();
  let fullDateTime = `${date}`;

  db.run(sql, new_emp_id, '', '', fullDateTime, function(err) {
    if(err)
    {
      return console.log(err.message);
    }
    else
    {
      console.log('can create');
      //ps.invoke(bee+' '+new_hire_id+'}');
      ps.invoke(bee+' '+new_emp_id);
      console.log('finished');
      return
    }
  });
  */
});



//when POST on termdate API
app.post('/api/termdate', API.authenticateKey, (req, res) => {
  
  res.status(200).send({
    data: 'accepted',
  });
  console.log("Term Date API:");
  console.log(req);

  let termed_emp_id = parseInt(req.body.Object_Identifier);

  let sql = 'INSERT INTO terminations VALUES(?,?,?,?,?)';
  let date = new Date();
  let fullDateTime = `${date}`;

  db.run(sql, termed_emp_id, '', '', fullDateTime, '', function(err) {
    if(err)
    {
      console.log('update');
      //return console.log(err.message);
      ps.invoke(terminator+' '+termed_emp_id);
    }
    else
    {
      console.log('new');
      //ps.invoke(bee+' '+new_hire_id+'}');
      ps.invoke(terminator+' '+termed_emp_id);
      //console.log('finished');
      return
    }
  });

});



//when POST on newhire API
app.post('/api/newhire', API.authenticateKey, (req, res) => {
  
  res.status(200).send({
    data: 'accepted',
  });
  console.log("New Hire API:");
  console.log(req);
  
  let new_hire_id = parseInt(req.body.Object_Identifier);

  console.log(new_hire_id);

  let sql = 'INSERT INTO new_hires VALUES(?,?,?,?)';
  let date = new Date();
  let fullDateTime = `${date}`;

  db.run(sql, new_hire_id, '', '', fullDateTime, function(err) {
    if(err)
    {
      return console.log(err.message);
    }
    else
    {
      console.log('can create');
      //ps.invoke(bee+' '+new_hire_id+'}');
      ps.invoke(bee+' '+new_hire_id);
      console.log('finished');
      return
    }
  });

});


//Staff departure, will need to reference the staff change event and check for an updated end date?
/*
app.post('/api/staffchange', API.authenticateKey, (req, res) => {
  
  res.status(200).send({
    data: 'accepted',
  });

  let staff_id = parseInt(req.body.Object_Identifier);

  console.log(staff_id);

  let sql = 'INSERT INTO terminations VALUES(?,?,?,?)';
  let date = new Date();
  let fullDateTime = `${date}`;

  db.run(sql, staff_id, '', '', fullDateTime, function(err) {
    if(err)
    {
      return console.log(err.message);
    }
    else
    {
      console.log('can create');
      ps.invoke(terminator+' '+staff_id+'}');
      console.log('finished');
      return
    }
  });

});
*/



const httpsOptions = {
    cert: fs.readFileSync('PATH_TO_YOUR_cert.pem'),
    ca: fs.readFileSync('PATH_TO_YOUR_fullchain.pem'),
    key: fs.readFileSync('PATH_TO_YOUR_privkey.pem')
};

const httpsServer = https.createServer(httpsOptions,app);


httpsServer.listen(8080, () => {
  console.log('HTTPS Server running on port 8080');
});





/*
let server = app.listen(8080, function() {
  console.log('Listening on port %d', server.address().port);
});
*/
