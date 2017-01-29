var express = require('express')
var app = express()
var mysql      = require('mysql')
var server = require('http').createServer(app);

var connection = mysql.createConnection({
  host     : 'localhost',
  user     : 'root',
  password : '',
  database : 'DJAnalytics'
});

connection.connect();

app.use('/', express.static(__dirname + '/'));

app.get('/songData', function (req, res) {
	connection.query('SELECT * from songs', function(err, rows, fields) {
	  if (!err){
	    console.log('The solution is: ', rows);
	    res.send(rows);
		}
	  else
	    console.log('Error while performing Query.');
	});
})

app.get('/index', function(req, res){
	res.sendFile(__dirname + '/mainpage.html');
})

app.get('/*', function(req, res){
	res.redirect('/index');
})

// app.get('/graph', function(req, res){
// 	res.sendFile(__dirname + '/tempo-graph.html');
// })

// app.get('/songs', function(req, res){
// 	res.sendFile(__dirname + '/songs.html');
// })

app.listen(3000, function () {
  console.log('Example app listening on port 3000!')
})