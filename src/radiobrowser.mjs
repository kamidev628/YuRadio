/*
It is not possible to do a reverse DNS from a browser yet.
The first part (a normal dns resolve) could be done from a browser by doing DOH (DNS over HTTPs)
to one of the providers out there. (google, quad9,...)
So we have to fallback to ask a single server for a list.
*/

/**
 * Ask a specified server for a list of all other server.
 */
export function get_radiobrowser_base_urls() {
  return new Promise((resolve, reject) => {
    var request = new XMLHttpRequest();
    // If you need https, you have to use fixed servers, at best a list for this request
    request.open("GET", "http://all.api.radio-browser.info/json/servers", true);
    request.onload = function () {
      if (request.status >= 200 && request.status < 300) {
        var items = JSON.parse(request.responseText).map(
          (x) => "https://" + x.name,
        );
        resolve(items);
      } else {
        reject(request.statusText);
      }
    };
    request.send();
  });
}

/**
 * Ask a server for its settings.
 */
export function get_radiobrowser_server_config(baseurl) {
  return new Promise((resolve, reject) => {
    var request = new XMLHttpRequest();
    request.open("GET", baseurl + "/json/config", true);
    request.onload = function () {
      if (request.status >= 200 && request.status < 300) {
        var items = JSON.parse(request.responseText);
        resolve(items);
      } else {
        reject(request.statusText);
      }
    };
    request.send();
  });
}

/**
 * Get a random available radio-browser server.
 * Returns: string - base url for radio-browser api
 */
export function get_radiobrowser_base_url_random() {
  return get_radiobrowser_base_urls().then((hosts) => {
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
