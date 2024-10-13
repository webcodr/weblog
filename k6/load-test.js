import http from "k6/http";
import { check, sleep } from "k6";

export const options = {
  vus: 100,
  duration: "1m",
  thresholds: {
    http_req_failed: ["rate<0.01"],
  },
  cloud: {
    distribution: {
      Frankfurt: { loadZone: "amazon:de:frankfurt", percent: 100 },
    },
  },
};

export default function () {
  const result = http.get("https://webcodr.io");

  check(result, { "is status 200": (r) => r.status == 200 });

  sleep(0.1);
}
