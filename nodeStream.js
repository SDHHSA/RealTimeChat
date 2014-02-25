//TCP chat server
//aug2uag © Sep 2013


//number of chattees
var numChattees = 0,
	users = []

//create telnet server
require('net').createServer(function(stream) {
	console.log('new chattee entered');
	var user_id = numChattees.toString();
	users[user_id] = stream;
	users.push(user_id);

	numChattees++;
	if (numChattees > 1) {stream.write('Welcome to Chat o! ' + numChattees +' chatters were in chatroom when you joined!');} else {stream.write('You were initially alone in Chat o :(')};

	stream.on('data', function(data){
		 var whatYouSaid = data.toString();
		 console.log(whatYouSaid);

		for (var i = users.length - 1; i >= 0; i--) {
			if (i >= 1 && users[(i-1)] != stream) {users[(i-1)].write(whatYouSaid);};
		};

	});

	stream.on('close', function() {
		numChattees--;
		users.splice((user_id), 1);

		for (var i = users.length - 1; i >= 0; i--) {
			if (i >= 1) {users[(i-1)].write('\na chattee has exited, specifically chattee ' + user_id);};
		};

		stream.end();

	});

	

}).listen(1230);
console.log('On port 1230');
