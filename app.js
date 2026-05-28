const SIGNAL_URL = "signal.json";

async function loadSignal() {

  try {

    const response = await fetch(`${SIGNAL_URL}?t=${Date.now()}`);

    if (!response.ok) {
      throw new Error("signal fetch failed");
    }

    const data = await response.json();

    renderSignal(data);

  } catch (error) {

    console.error(error);

    document.getElementById("inference").textContent =
      "telemetry unavailable";

    document.getElementById("signal").textContent =
      "UNKNOWN";

  }
}

function renderSignal(data) {

  const wakefulness =
    data.wakefulness || "UNKNOWN";

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
