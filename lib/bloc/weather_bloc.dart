import 'package:airhygro/data/my_data.dart';
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:weather/weather.dart';

part 'weather_event.dart';
part 'weather_state.dart';

class WeatherBloc extends Bloc<WeatherEvent, WeatherState> {
  WeatherBloc() : super(WeatherInitial()) {
    on<FetchWeather>((event, emit) async {
      emit(WeatherLoading());
      try {
        // Check location permissions
        LocationPermission permission = await Geolocator.checkPermission();
        if (permission == LocationPermission.denied) {
          permission = await Geolocator.requestPermission();
          if (permission == LocationPermission.denied) {
            emit(WeatherFailure());
            return;
          }
        }

        if (permission == LocationPermission.deniedForever) {
          emit(WeatherFailure());
          return;
        }

        // Check if location services are enabled
        bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
        if (!serviceEnabled) {
          emit(WeatherFailure());
          return;
        }

        WeatherFactory wf = WeatherFactory(apiKey, language: Language.ENGLISH);
        Position position = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high,
          ),
        );

        // Fetch current weather for immediate display
        Weather currentWeather = await wf.currentWeatherByLocation(
          position.latitude,
          position.longitude,
        );

        // Fetch 5-day forecast to get proper min/max temperatures
        List<Weather> forecast = await wf.fiveDayForecastByLocation(
          position.latitude,
          position.longitude,
        );

        // Debug: Print what we're getting from the API
        debugPrint(
            'Current weather tempMin: ${currentWeather.tempMin?.celsius}');
        debugPrint(
            'Current weather tempMax: ${currentWeather.tempMax?.celsius}');
        debugPrint('Forecast length: ${forecast.length}');

        if (forecast.isNotEmpty) {
          debugPrint(
              'First forecast tempMin: ${forecast.first.tempMin?.celsius}');
          debugPrint(
              'First forecast tempMax: ${forecast.first.tempMax?.celsius}');
          debugPrint('First forecast date: ${forecast.first.date}');
        }

        emit(WeatherSuccess(currentWeather, forecast));
      } catch (e) {
        // Log error for debugging
        debugPrint('Error fetching weather: $e');
        emit(WeatherFailure());
      }
    });
  }
}
