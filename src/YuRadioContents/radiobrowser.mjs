/*
It is not possible to do a reverse DNS from a browser yet.
The first part (a normal dns resolve) could be done from a browser by doing DOH (DNS over HTTPs)
to one of the providers out there. (google, quad9,...)
So we have to fallback to ask a single server for a list.
*/

function makeRequest(url, onSuccess) {
  return new Promise((resolve, reject) => {
    const request = new XMLHttpRequest();
    request.open("GET", url, true);
    request.onload = () => {
      if (request.status >= 200 && request.status < 300) {
        resolve(onSuccess(request.responseText));
      } else {
        reject(request.statusText);
      }
    };
    request.send();
  });
}

export function click(baseUrl, stationUUID) {
  return makeRequest(baseUrl + "/json/url/" + stationUUID, (data) => {
    return JSON.parse(data);
  });
}

export function vote(baseUrl, stationUUID) {
  return makeRequest(baseUrl + "/json/vote/" + stationUUID, (data) => {
    return JSON.parse(data);
  });
}

/**
 * Ask a specified server for a list of all other server.
 */
export function baseUrls() {
  return makeRequest(
    "http://all.api.radio-browser.info/json/servers",
    (data) => {
      return JSON.parse(data).map((x) => "https://" + x.name);
    },
  );
}

/**
 * Ask a server for its settings.
 */
export function serverConfig(baseurl) {
  return makeRequest(baseurl + "/json/config", (data) => {
    return JSON.parse(data);
  });
}

/**
 * Get a random available radio-browser server.
 * Returns: string - base url for radio-browser api
 */
export function baseUrlRandom() {
  return this.baseUrls().then((hosts) => {
    return hosts[Math.floor(Math.random() * hosts.length)];
  });
}

//
//get_radiobrowser_base_url_random().then((x)=>{
//    console.log("-",x);
//    return get_radiobrowser_server_config(x);
//}).then(config=>{
//    console.log("config:",config);
//});
