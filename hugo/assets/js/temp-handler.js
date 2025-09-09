document.addEventListener("DOMContentLoaded", function() {
    fetch("http://temp-handler.main-temp-handler.app.lagoon.jwrf.au/api/v1/status")
        .then(res => res.json())
        .then(data => {
            const tempElem = document.getElementById("temperature");
            const humElem = document.getElementById("humidity");

            if (tempElem) tempElem.textContent = `Temperature: ${data.temp.toFixed(2)} °C`;
            if (humElem) humElem.textContent = `Humidity: ${data.humidity.toFixed(2)} %`;
        })
        .catch(err => console.error("Failed to fetch sensor data", err));
});
