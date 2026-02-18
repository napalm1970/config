import unittest
from unittest.mock import patch, MagicMock
import json
import check_weather
import io
import sys

class TestCheckWeather(unittest.TestCase):

    @patch('check_weather.subprocess.run')
    @patch('check_weather.urllib.request.urlopen')
    def test_get_weather_success(self, mock_urlopen, mock_subprocess):
        # Mock 'pass' output
        mock_subprocess.return_value.stdout = "fake_api_key\n"

        # Mock API response
        mock_response = MagicMock()
        mock_response.read.return_value = json.dumps({
            "main": {
                "temp": 20.5,
                "feels_like": 22.1,
                "humidity": 60
            },
            "weather": [{
                "description": "clear sky",
                "icon": "01d"
            }],
            "wind": {
                "speed": 5.5
            }
        }).encode('utf-8')
        mock_urlopen.return_value.__enter__.return_value = mock_response

        # Capture stdout
        captured_output = io.StringIO()
        sys.stdout = captured_output

        check_weather.get_weather()

        sys.stdout = sys.__stdout__

        output = json.loads(captured_output.getvalue())

        self.assertEqual(output['text'], "☀️ 20°C")
        self.assertIn("Clear sky", output['tooltip'])
        self.assertEqual(output['class'], "weather")

    @patch('check_weather.subprocess.run')
    def test_get_api_key_failure(self, mock_subprocess):
        # Mock 'pass' failure
        mock_subprocess.side_effect = check_weather.subprocess.CalledProcessError(1, ['pass'])

        # Capture stdout
        captured_output = io.StringIO()
        sys.stdout = captured_output

        check_weather.get_weather()

        sys.stdout = sys.__stdout__

        output = json.loads(captured_output.getvalue())

        self.assertEqual(output['text'], "Key Error")
        self.assertEqual(output['class'], "error")

if __name__ == '__main__':
    unittest.main()
