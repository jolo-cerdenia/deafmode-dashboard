const SIGNAL_URL = "signal.json";
const WAKEFULNESS_URL = "wakefulness.json";

async function loadDashboard() {

  await Promise.all([
    loadSignal(),
    loadWakefulness()
  ]);
}

async function loadSignal() {

  try {

    const response =
      await fetch(`${SIGNAL_URL}?t=${Date.now()}`);

    if (!response.ok) {
      throw new Error("signal fetch failed");
    }

    const data = await response.json();

    renderSignal(data);

  } catch (error) {

    console.error(error);

    document.getElementById("signal").textContent =
      "UNKNOWN";

    document.getElementById("inference").textContent =
      "telemetry unavailable";
  }
}

async function loadWakefulness() {

  try {

    const response =
      await fetch(`${WAKEFULNESS_URL}?t=${Date.now()}`);

    if (!response.ok) {
      throw new Error("wakefulness fetch failed");
    }

    const data = await response.json();

    renderWakefulness(data);

  } catch (error) {

    console.error(error);

    document.getElementById("wakefulness").textContent =
      "UNKNOWN";
  }
}

function renderSignal(data) {

  const signal =
    data.signal || "UNKNOWN";

  const inference =
    data.inference || "awaiting inference";

  const drift =
    data.drift || "no active drift";

  const response =
    data.response || "maintain operational stability";

  const generatedAt =
    data.generated_at || "unknown";

  document.getElementById("signal").textContent =
    signal;

  document.getElementById("inference").textContent =
    inference;

  document.getElementById("drift").textContent =
    drift;

  document.getElementById("response").textContent =
    response;

  document.getElementById("timestamp").textContent =
    `last update ${generatedAt}`;
}

function renderWakefulness(data) {

  const lastSeen =
    new Date(data.last_seen);

  const now =
    new Date();

  const diffMinutes =
    (now - lastSeen) / 1000 / 60;

  let state = "UNKNOWN";

  if (diffMinutes <= 20) {
    state = "AWAKE";
  } else {
    state = "ASLEEP";
  }

  document.getElementById("wakefulness").textContent =
    state;
}

loadDashboard();

setInterval(loadDashboard, 60000);
  const inference =
    data.inference || "awaiting inference";

  const drift =
    data.drift || "no active drift";

  const response =
    data.response || "maintain operational stability";

  const generatedAt =
    data.generated_at || "unknown";

  document.getElementById("wakefulness").textContent =
    wakefulness;

  document.getElementById("signal").textContent =
    signal;

  document.getElementById("inference").textContent =
    inference;

  document.getElementById("drift").textContent =
    drift;

  document.getElementById("response").textContent =
    response;

  document.getElementById("timestamp").textContent =
    `last update ${generatedAt}`;
}

loadSignal();

setInterval(loadSignal, 60000);
