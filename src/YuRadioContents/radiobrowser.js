.pragma library

/*
It is not possible to do a reverse DNS from a browser yet.
The first part (a normal dns resolve) could be done from a browser by doing DOH (DNS over HTTPs)
to one of the providers out there. (google, quad9,...)
So we have to fallback to ask a single server for a list.
*/

function getTopUsedTags(count) {
  return makeRestRequest(
    `/json/tags?order=stationcount&reverse=true&limit=${count}`,
  );
}

function getLanguages() {
  return makeRestRequest("/json/languages");
}

function getStation(stationUUID) {
  return makeRestRequest(`/json/stations/byuuid/${stationUUID}`).then(
    (stations) => stations[0],
  );
}

function getCountries() {
  return makeRestRequest("/json/countries");
}

function click(stationUUID) {
  return makeRestRequest(`/json/url/${stationUUID}`);
}

function vote(stationUUID) {
  return makeRestRequest(`/json/vote/${stationUUID}`);
}

/**
 * Ask a specified server for a list of all other server.
 */
function baseUrls() {
  return makeRequest("http://all.api.radio-browser.info/json/servers").then(
    (servers) => servers.map((x) => "https://" + x.name),
  );
}

/**
 * Ask a server for its settings.
 */
function serverConfig() {
  return makeRestRequest("/json/config");
}

/**
 * Get a random available radio-browser server.
 * Returns: string - base url for radio-browser api
 */
function baseUrlRandom() {
  return baseUrls().then((hosts) => {
    return hosts[Math.floor(Math.random() * hosts.length)];
  });
}

var baseUrl;

function makeRestRequest(path) {
  return makeRequest(baseUrl + path)
}

function makeRequest(url) {
  return new Promise((resolve, reject) => {
    const request = new XMLHttpRequest();
    request.open("GET", url, true);
    request.onload = () => {
      if (request.status >= 200 && request.status < 300) {
        resolve(JSON.parse(request.responseText));
      } else {
        console.log(`[RadioBrowser: ${url}][Error]: ${request.statusText}`);
        reject(request.statusText);
      }
    };
    request.send();
  });
}
