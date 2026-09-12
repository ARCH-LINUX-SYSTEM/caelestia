pragma Singleton

import QtQuick
import Quickshell
import Caelestia
import Caelestia.Config
import qs.utils

Singleton {
    id: root

    property string city
    property string loc
    property var cc
    property list<var> forecast
    property list<var> hourlyForecast

    readonly property string icon: cc ? Icons.getWeatherIcon(cc.weatherCode) : "cloud_alert"
    readonly property string description: cc?.weatherDesc ?? qsTr("Không có dữ liệu thời tiết")
    readonly property string temp: formatTemp(cc?.tempC)
    readonly property string feelsLike: formatTemp(cc?.feelsLikeC)
    readonly property int humidity: cc?.humidity ?? 0
    readonly property real windSpeed: cc?.windSpeed ?? 0
    readonly property string sunrise: cc ? Qt.formatDateTime(new Date(cc.sunrise), GlobalConfig.services.useTwelveHourClock ? "h:mm A" : "h:mm") : "--:--"
    readonly property string sunset: cc ? Qt.formatDateTime(new Date(cc.sunset), GlobalConfig.services.useTwelveHourClock ? "h:mm A" : "h:mm") : "--:--"

    readonly property var cachedCities: new Map()

    function formatTemp(temp: var): string {
        return GlobalConfig.services.useFahrenheit ? `${temp !== undefined ? Math.round(toFahrenheit(temp)) : "--"}°F` : `${temp !== undefined ? Math.round(temp) : "--"}°C`;
    }

    function languageCode(): string {
        const configured = GlobalConfig.language.ui.trim();
        const locale = configured && configured !== "auto" ? configured : Qt.locale().name;
        return locale.replace("-", "_").split("_")[0] || "en";
    }

    function requestHeaders(): var {
        const userAgent = GlobalConfig.services.networkUserAgent.trim();
        return userAgent ? {
            "User-Agent": userAgent
        } : {};
    }

    function reload(): void {
        const barWeather = GlobalConfig.bar.weather;
        const configLocation = barWeather.enable ? (barWeather.enableGPS ? "" : barWeather.city) : (GlobalConfig.services.weatherUseGps ? "" : GlobalConfig.services.weatherLocation);

        if (configLocation) {
            if (configLocation.indexOf(",") !== -1 && !isNaN(parseFloat(configLocation.split(",")[0]))) {
                loc = configLocation;
                fetchCityFromCoords(configLocation);
            } else {
                fetchCoordsFromCity(configLocation);
            }
        } else if (!loc || timer.elapsed() > 900) {
            Requests.get("https://ipinfo.io/json", text => {
                const response = JSON.parse(text);
                if (response.loc) {
                    loc = response.loc;
                    city = response.city ?? "";
                    timer.restart();
                }
            }, null, requestHeaders());
        }
    }

    function fixCityName(cityName: string): string {
        if (!cityName)
            return "";
        const mapping = {
            // Polish
            "Poznan": "Poznań",
            "Wroclaw": "Wrocław",
            "Krakow": "Kraków",
            "Gdansk": "Gdańsk",
            "Lodz": "Łódź",
            "Rzeszow": "Rzeszów",
            "Torun": "Toruń",
            "Bialystok": "Białystok",
            "Czestochowa": "Częstochowa",
            "Plock": "Płock",
            "Ruda Slaska": "Ruda Śląska",
            "Dabrowa Gornicza": "Dąbrowa Górnicza",
            "Elblag": "Elbląg",
            "Gorzow Wielkopolski": "Gorzów Wielkopolski",
            "Zielona Gora": "Zielona Góra",
            "Slupsk": "Słupsk",

            // German
            "Munchen": "München",
            "Koln": "Köln",
            "Dusseldorf": "Düsseldorf",
            "Nurnberg": "Nürnberg",

            // French & Spanish & Portuguese
            "Sao Paulo": "São Paulo",
            "Montreal": "Montréal",
            "Quebec": "Québec",
            "Bogota": "Bogotá",
            "Medellin": "Medellín",
            "Cordoba": "Córdoba",

            // Turkish
            "Istanbul": "İstanbul",
            "Izmir": "İzmir",

            // Scandinavian & others
            "Malmo": "Malmö",
            "Goteborg": "Göteborg",
            "Zurich": "Zürich",
            "Geneve": "Genève"
        };
        return mapping[cityName] || cityName;
    }

    function fetchCityFromCoords(coords: string): void {
        if (cachedCities.has(coords)) {
            city = cachedCities.get(coords);
            return;
        }

        const [lat, lon] = coords.split(",").map(s => s.trim());
        const lang = languageCode();

        const fallbackToBigDataCloud = () => {
            const fallbackUrl = `https://api.bigdatacloud.net/data/reverse-geocode-client?latitude=${lat}&longitude=${lon}&localityLanguage=${lang}`;
            Requests.get(fallbackUrl, text => {
                const geo = JSON.parse(text);
                const geoCity = geo.city || geo.locality;
                if (geoCity) {
                    city = fixCityName(geoCity);
                    cachedCities.set(coords, city);
                } else {
                    city = qsTr("Không rõ thành phố");
                }
            }, null, requestHeaders());
        };

        const nominatimUrl = `https://nominatim.openstreetmap.org/reverse?lat=${lat}&lon=${lon}&format=geocodejson&accept-language=${lang}`;
        Requests.get(nominatimUrl, text => {
            const geo = JSON.parse(text).features?.[0]?.properties.geocoding;
            if (geo) {
                const geoCity = geo.type === "city" ? geo.name : geo.city;
                if (geoCity) {
                    city = fixCityName(geoCity);
                    cachedCities.set(coords, city);
                    return;
                }
            }
            fallbackToBigDataCloud();
        }, fallbackToBigDataCloud, requestHeaders());
    }

    function fetchCoordsFromCity(cityName: string): void {
        const lang = languageCode();
        const url = `https://geocoding-api.open-meteo.com/v1/search?name=${encodeURIComponent(cityName)}&count=1&language=${lang}&format=json`;

        Requests.get(url, text => {
            const json = JSON.parse(text);
            if (json.results && json.results.length > 0) {
                const result = json.results[0];
                loc = result.latitude + "," + result.longitude;
                city = fixCityName(result.name);
            } else {
                loc = "";
                reload();
            }
        }, null, requestHeaders());
    }

    function fetchWeatherData(): void {
        const url = getWeatherUrl();
        if (url === "")
            return;

        Requests.get(url, text => {
            const json = JSON.parse(text);
            if (!json.current || !json.daily)
                return;

            cc = {
                weatherCode: json.current.weather_code,
                weatherDesc: getWeatherCondition(json.current.weather_code),
                tempC: json.current.temperature_2m,
                feelsLikeC: json.current.apparent_temperature,
                humidity: json.current.relative_humidity_2m,
                windSpeed: json.current.wind_speed_10m,
                isDay: json.current.is_day,
                sunrise: json.daily.sunrise[0].replace("T", " "),
                sunset: json.daily.sunset[0].replace("T", " ")
            };

            const forecastList = [];
            for (let i = 0; i < json.daily.time.length; i++)
                forecastList.push({
                    date: json.daily.time[i].replace(/-/g, "/"),
                    maxTempC: json.daily.temperature_2m_max[i],
                    minTempC: json.daily.temperature_2m_min[i],
                    weatherCode: json.daily.weather_code[i],
                    icon: Icons.getWeatherIcon(json.daily.weather_code[i])
                });
            forecast = forecastList;

            const hourlyList = [];
            const now = new Date();
            for (let i = 0; i < json.hourly.time.length; i++) {
                const time = new Date(json.hourly.time[i].replace("T", " "));

                if (time < now)
                    continue;

                hourlyList.push({
                    timestamp: json.hourly.time[i],
                    hour: time.getHours(),
                    tempC: Math.round(json.hourly.temperature_2m[i]),
                    precipChance: json.hourly.precipitation_probability[i],
                    weatherCode: json.hourly.weather_code[i],
                    icon: Icons.getWeatherIcon(json.hourly.weather_code[i])
                });
            }
            hourlyForecast = hourlyList;
        }, null, requestHeaders());
    }

    function toFahrenheit(celcius: real): real {
        return celcius * 9 / 5 + 32;
    }

    function getWeatherUrl(): string {
        if (!loc || loc.indexOf(",") === -1)
            return "";

        const [lat, lon] = loc.split(",").map(s => s.trim());
        const baseUrl = "https://api.open-meteo.com/v1/forecast";
        const params = ["latitude=" + lat, "longitude=" + lon, "hourly=weather_code,temperature_2m,precipitation_probability", "daily=weather_code,temperature_2m_max,temperature_2m_min,sunrise,sunset", "current=temperature_2m,relative_humidity_2m,apparent_temperature,is_day,weather_code,wind_speed_10m", "timezone=auto", "forecast_days=7"];

        return baseUrl + "?" + params.join("&");
    }

    function getWeatherCondition(code: string): string {
        const conditions = {
            "0": qsTr("Trời quang"),
            "1": qsTr("Trời quang"),
            "2": qsTr("Mây rải rác"),
            "3": qsTr("Trời âm u"),
            "45": qsTr("Sương mù"),
            "48": qsTr("Sương mù"),
            "51": qsTr("Mưa phùn"),
            "53": qsTr("Mưa phùn"),
            "55": qsTr("Mưa phùn"),
            "56": qsTr("Mưa phùn đóng băng"),
            "57": qsTr("Mưa phùn đóng băng"),
            "61": qsTr("Mưa nhẹ"),
            "63": qsTr("Mưa"),
            "65": qsTr("Mưa lớn"),
            "66": qsTr("Mưa nhẹ"),
            "67": qsTr("Mưa lớn"),
            "71": qsTr("Tuyết nhẹ"),
            "73": qsTr("Tuyết"),
            "75": qsTr("Tuyết rơi dày"),
            "77": qsTr("Tuyết"),
            "80": qsTr("Mưa nhẹ"),
            "81": qsTr("Mưa"),
            "82": qsTr("Mưa lớn"),
            "85": qsTr("Tuyết rơi rải rác nhẹ"),
            "86": qsTr("Tuyết rơi rải rác dày"),
            "95": qsTr("Dông"),
            "96": qsTr("Dông kèm mưa đá"),
            "99": qsTr("Dông kèm mưa đá")
        };
        return conditions[code] || qsTr("Không rõ");
    }

    onLocChanged: fetchWeatherData()

    Connections {
        function onWeatherLocationChanged(): void {
            root.reload();
        }

        function onWeatherUseGpsChanged(): void {
            root.reload();
        }

        target: GlobalConfig.services
    }

    Connections {
        function onUiChanged(): void {
            root.cachedCities.clear();
            root.reload();
        }

        target: GlobalConfig.language
    }

    Connections {
        function onEnableChanged(): void {
            root.reload();
        }

        function onEnableGPSChanged(): void {
            root.reload();
        }

        function onCityChanged(): void {
            root.reload();
        }

        target: GlobalConfig.bar.weather
    }

    Timer {
        interval: (GlobalConfig.bar.weather.enable ? GlobalConfig.bar.weather.fetchInterval : GlobalConfig.services.weatherFetchInterval) * 60000
        running: true
        repeat: true
        onTriggered: fetchWeatherData()
    }

    ElapsedTimer {
        id: timer
    }
}
