fs = require 'fs'
request = require 'request'
qs = require 'querystring'

class FixtureHelper
  fixturePath: (fileName) =>
    "#{__dirname}/../fixtures/#{fileName}"

  tmpPath: (fileName) =>
    "#{__dirname}/../tmp/#{fileName}"

  cleanTmpFiles: (fileNames) =>
    for file in fileNames
      try
        fs.unlinkSync @tmpPath(file)
      catch ignore

  loadJsonFixture: (fixtureName) =>
    data = fs.readFileSync @fixturePath(fixtureName), "utf-8"
    JSON.parse data
 
  loadFixture: (fixtureName) =>
    fs.readFileSync @fixturePath(fixtureName), "utf-8"
    

module.exports = new FixtureHelper()
