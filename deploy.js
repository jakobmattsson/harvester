var fs = require('fs');
var opra = require('opra');
var powerfs = require('powerfs');
var knox = require('knox');

var bucket = 'harvester.jdevab.com';

fs.readFile('config.json', 'utf8', function(err, data) {
  if (err) {
    console.log(err);
    return;
  }

  var config = JSON.parse(data);

  var client = knox.createClient({
    key: config.aws.key,
    secret: config.aws.secret,
    bucket: bucket,
    endpoint: bucket + '.s3-external-3.amazonaws.com'
  });

  opra.build('public/index.html', { inline: true }, function(err, data) {
    console.log(err);
    powerfs.writeFile('tmp/index.html', data, 'utf8', function(err) {
      console.log(err);
      client.putFile('tmp/index.html', '/index.html', function(err, res) {
        console.log(err);
        console.log("done");
      });
    });
  });
});
