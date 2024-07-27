/*
It is not possible to do a reverse DNS from a browser yet.
The first part (a normal dns resolve) could be done from a browser by doing DOH (DNS over HTTPs)
to one of the providers out there. (google, quad9,...)
So we have to fallback to ask a single server for a list.
*/

export default class RadioBrowser {
  constructor() {}

  click(baseUrl, stationUUID) {
    return new Promise((resolve, reject) => {
      const request = new XMLHttpRequest();
      request.open("GET", baseUrl + "/json/url/" + stationUUID, true);
      request.onload = () => {
        if (request.status >= 200 && request.status < 300) {
          resolve(JSON.parse(request.responseText));
        } else {
          reject(request.statusText);
        }
      };
      request.send();
    });
  }

  /**
   * Ask a specified server for a list of all other server.
   */
  baseUrls() {
    return new Promise((resolve, reject) => {
      const request = new XMLHttpRequest();
      // If you need https, you have to use fixed servers, at best a list for this request
      request.open(
        "GET",
        "http://all.api.radio-browser.info/json/servers",
        true,
      );
      request.onload = () => {
        if (request.status >= 200 && request.status < 300) {
          const items = JSON.parse(request.responseText).map(
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
  serverConfig(baseurl) {
    return new Promise((resolve, reject) => {
      const request = new XMLHttpRequest();
      request.open("GET", baseurl + "/json/config", true);
      request.onload = () => {
        if (request.status >= 200 && request.status < 300) {
          const items = JSON.parse(request.responseText);
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
  baseUrlRandom() {
    return this.baseUrls().then((hosts) => {
      return hosts[Math.floor(Math.random() * hosts.length)];
    });
  }
}

//
//get_radiobrowser_base_url_random().then((x)=>{
//    console.log("-",x);
//    return get_radiobrowser_server_config(x);
//}).then(config=>{
//    console.log("config:",config);
//});
