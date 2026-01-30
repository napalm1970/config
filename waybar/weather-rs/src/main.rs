use reqwest::blocking::Client;
use serde::Deserialize;
use serde_json::json;
use std::thread;
use std::time::Duration;

// Конфигурация
const CITY: &str = "Sompa,Kohtla-Jarve";
const MAX_RETRIES: u32 = 10;
const RETRY_DELAY: u64 = 5;

// Описываем структуру JSON ответа, который мы ожидаем от wttr.in
// Нам нужны не все поля, а только те, что мы используем.
#[derive(Deserialize, Debug)]
struct WttrResponse {
    current_condition: Vec<CurrentCondition>,
}

#[derive(Deserialize, Debug)]
struct CurrentCondition {
    #[serde(rename = "temp_C")]
    temp_c: String,
    #[serde(rename = "weatherCode")]
    weather_code: String,
    #[serde(rename = "weatherDesc")]
    weather_desc: Vec<WeatherDesc>,
    #[serde(rename = "FeelsLikeC")]
    feels_like_c: String,
    humidity: String,
    #[serde(rename = "windspeedKmph")]
    wind_speed_kmph: String,
}

#[derive(Deserialize, Debug)]
struct WeatherDesc {
    value: String,
}

fn get_icon(code: &str) -> &str {
    match code {
        "113" => "☀️",  // Sunny
        "116" => "⛅",  // PartlyCloudy
        "119" => "☁️",  // Cloudy
        "122" => "☁️",  // VeryCloudy
        "143" => "🌫️",  // Fog
        "176" => "🌦️",  // LightShowers
        "179" => "🌨️",  // LightSleetShowers
        "182" => "🌨️",  // LightSleet
        "185" => "🌨️",  // LightSleet
        "200" => "⛈️",  // ThunderyShowers
        "227" => "🌨️",  // LightSnow
        "230" => "❄️",  // HeavySnow
        "248" => "🌫️",  // Fog
        "260" => "🌫️",  // Fog
        "263" => "🌦️",  // LightShowers
        "266" => "🌧️",  // LightRain
        "281" => "🌨️",  // LightSleet
        "284" => "🌨️",  // LightSleet
        "293" => "🌧️",  // LightRain
        "296" => "🌧️",  // LightRain
        "299" => "🌧️",  // HeavyShowers
        "302" => "🌧️",  // HeavyRain
        "305" => "🌧️",  // HeavyShowers
        "308" => "🌧️",  // HeavyRain
        "311" => "🌨️",  // LightSleet
        "314" => "🌨️",  // LightSleet
        "317" => "🌨️",  // LightSleet
        "320" => "🌨️",  // LightSnow
        "323" => "🌨️",  // LightSnowShowers
        "326" => "🌨️",  // LightSnowShowers
        "329" => "❄️",  // HeavySnow
        "332" => "❄️",  // HeavySnow
        "335" => "❄️",  // HeavySnowShowers
        "338" => "❄️",  // HeavySnow
        "350" => "🌨️",  // LightSleet
        "353" => "🌦️",  // LightShowers
        "356" => "🌧️",  // HeavyShowers
        "359" => "🌧️",  // HeavyRain
        "362" => "🌨️",  // LightSleetShowers
        "365" => "🌨️",  // LightSleetShowers
        "368" => "🌨️",  // LightSnowShowers
        "371" => "❄️",  // HeavySnowShowers
        "374" => "🌨️",  // LightSleetShowers
        "377" => "🌨️",  // LightSleet
        "386" => "⛈️",  // ThunderyShowers
        "389" => "⛈️",  // ThunderyHeavyRain
        "392" => "⛈️",  // ThunderySnowShowers
        "395" => "❄️",  // HeavySnowShowers
        _ => "❓",      // Unknown
    }
}

fn main() {
    let url = format!("https://wttr.in/{}?format=j1", CITY);
    let client = Client::builder()
        .timeout(Duration::from_secs(5))
        .build()
        .unwrap_or_else(|_| Client::new());

    for _ in 0..MAX_RETRIES {
        match client.get(&url).send() {
            Ok(resp) => {
                if resp.status().is_success() {
                    // Пытаемся распарсить JSON в нашу структуру WttrResponse
                    match resp.json::<WttrResponse>() {
                        Ok(data) => {
                            if let Some(condition) = data.current_condition.first() {
                                let icon = get_icon(&condition.weather_code);
                                let desc = condition.weather_desc.first().map(|d| d.value.as_str()).unwrap_or("");
                                
                                let text = format!("{} {}°C", icon, condition.temp_c);
                                let tooltip = format!(
                                    "<b>{}</b>\nОщущается как: {}°C\nВлажность: {}%\nВетер: {} km/h",
                                    desc,
                                    condition.feels_like_c,
                                    condition.humidity,
                                    condition.wind_speed_kmph
                                );

                                // Выводим JSON для waybar
                                let output = json!({
                                    "text": text,
                                    "tooltip": tooltip,
                                    "class": "weather"
                                });
                                println!("{}", output);
                                return;
                            }
                        }
                        Err(e) => {
                            let output = json!({ "text": "Error", "tooltip": format!("JSON error: {}", e) });
                            println!("{}", output);
                            return;
                        }
                    }
                }
            }
            Err(_) => {
                // Ошибка сети, ждем и пробуем снова
                thread::sleep(Duration::from_secs(RETRY_DELAY));
            }
        }
    }

    // Если все попытки исчерпаны
    let output = json!({
        "text": "🚫", 
        "tooltip": "No Internet Connection"
    });
    println!("{}", output);
}