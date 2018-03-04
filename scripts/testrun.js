// Generated by CoffeeScript 2.2.2
(function() {
  //!/usr/local/bin/coffee

  // WTF = require 'wtfnode'
  var Identity, Tradfri, sleep, tradfri;

  require('promise.prototype.finally').shim();

  Tradfri = require('../src/Tradfri');

  Identity = require('../identity');

  sleep = function(time = 10) {
    return new Promise(function(resolve, reject) {
      return setTimeout(resolve, time * 1000);
    });
  };

  tradfri = new Tradfri('tradfri.tallinn.may.be', Identity); //.id

  tradfri.connect().then(async function(credentials) {
    var group, groups, i, len;
    console.log("Credentials: ", credentials);
    console.log('------------------------------------');
    groups = [tradfri.group('Living Room'), tradfri.group('Hallway')];
    console.log(groups);
    console.log((function() {
      var i, len, results;
      results = [];
      for (i = 0, len = groups.length; i < len; i++) {
        group = groups[i];
        results.push(group.scenes);
      }
      return results;
    })());
    for (i = 0, len = groups.length; i < len; i++) {
      group = groups[i];
      // group.switch = on for group in groups
      await group.setScene('FOCUS');
    }
    return console.log((function() {
      var j, len1, results;
      results = [];
      for (j = 0, len1 = groups.length; j < len1; j++) {
        group = groups[j];
        results.push(group.scene);
      }
      return results;
    })());
  }).catch(function(err) {
    return console.log(err);
  }).finally(async function() {
    await sleep(10);
    console.log('Closing...');
    tradfri.close();
    return process.exit();
  });

  // WTF.dump()

}).call(this);