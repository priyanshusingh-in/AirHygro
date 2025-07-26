import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:airhygro/bloc/weather_bloc.dart';
import 'package:intl/intl.dart';
import 'package:lottie/lottie.dart';
import 'package:weather/weather.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        systemOverlayStyle:
            SystemUiOverlayStyle(statusBarBrightness: Brightness.dark),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: () {
              context.read<WeatherBloc>().add(FetchWeather());
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          // Fixed background elements that don't scroll
          Positioned.fill(
            child: Stack(
              children: [
                // Orange gradient background at the top
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  height: 300,
                  child: Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Colors.orangeAccent, Colors.deepOrange],
                      ),
                    ),
                  ),
                ),
                // Purple circles
                Positioned(
                  top: 100,
                  right: -100,
                  child: Container(
                    height: 300,
                    width: 300,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.deepPurple.withValues(alpha: 0.8),
                    ),
                  ),
                ),
                Positioned(
                  top: 100,
                  left: -100,
                  child: Container(
                    height: 300,
                    width: 300,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.deepPurple.withValues(alpha: 0.8),
                    ),
                  ),
                ),
                // Blur overlay for better text readability
                BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 50, sigmaY: 50),
                  child: Container(
                    color: Colors.transparent,
                  ),
                ),
              ],
            ),
          ),
          // Scrollable content
          RefreshIndicator(
            onRefresh: () async {
              context.read<WeatherBloc>().add(FetchWeather());
            },
            child: BlocBuilder<WeatherBloc, WeatherState>(
              builder: (context, state) {
                return SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(
                        40, 1.2 * kToolbarHeight, 40, 20),
                    child: SizedBox(
                      height: MediaQuery.of(context).size.height,
                      child: _buildWeatherContent(context, state),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeatherContent(BuildContext context, WeatherState state) {
    if (state is WeatherLoading) {
      return Center(
        child: Lottie.asset(
          'assets/weather icon-Og4Gs.json',
          width: 200,
          height: 200,
          fit: BoxFit.contain,
        ),
      );
    }

    if (state is WeatherFailure) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Colors.white, size: 64),
            const SizedBox(height: 20),
            const Text(
              'Failed to load weather data',
              style: TextStyle(color: Colors.white, fontSize: 18),
            ),
            const SizedBox(height: 10),
            const Text(
              'Please check your location permissions and internet connection',
              style: TextStyle(color: Colors.white70, fontSize: 14),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                context.read<WeatherBloc>().add(FetchWeather());
              },
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (state is WeatherSuccess) {
      final currentWeather = state.currentWeather;
      final forecast = state.forecast;
      final now = DateTime.now();
      final timeFormat = DateFormat('EEEE d • h:mm a');

      // Get today's forecast for min/max temperatures
      double? calculatedTodayMin;
      double? calculatedTodayMax;

      if (forecast.isNotEmpty) {
        // Find today's forecast by comparing dates
        final today = DateTime(now.year, now.month, now.day);

        // Debug: Print forecast dates to understand the data structure
        debugPrint('Current date: $today');
        for (int i = 0; i < forecast.length; i++) {
          debugPrint('Forecast $i date: ${forecast[i].date}');
          debugPrint('Forecast $i tempMin: ${forecast[i].tempMin?.celsius}');
          debugPrint('Forecast $i tempMax: ${forecast[i].tempMax?.celsius}');
        }

        // Calculate actual min/max for today from all hourly forecasts
        for (final weather in forecast) {
          if (weather.date != null) {
            final forecastDate = DateTime(
              weather.date!.year,
              weather.date!.month,
              weather.date!.day,
            );

            // Check if this forecast is for today
            if (forecastDate.isAtSameMomentAs(today)) {
              // Update min temperature
              if (weather.temperature?.celsius != null) {
                final temp = weather.temperature!.celsius!;
                if (calculatedTodayMin == null || temp < calculatedTodayMin!) {
                  calculatedTodayMin = temp;
                }
                if (calculatedTodayMax == null || temp > calculatedTodayMax!) {
                  calculatedTodayMax = temp;
                }
              }
            }
          }
        }

        debugPrint(
            'Calculated today min: $calculatedTodayMin, max: $calculatedTodayMax');
      }

      // Debug: Print what we're using for min/max
      debugPrint('Current weather tempMin: ${currentWeather.tempMin?.celsius}');
      debugPrint('Current weather tempMax: ${currentWeather.tempMax?.celsius}');
      debugPrint('Today forecast tempMin: ${calculatedTodayMin}');
      debugPrint('Today forecast tempMax: ${calculatedTodayMax}');

      // Calculate fallback min/max if forecast data is not available or same values
      double? fallbackMin;
      double? fallbackMax;

      if (currentWeather.temperature?.celsius != null) {
        final currentTemp = currentWeather.temperature!.celsius!;
        // Use a reasonable range: -3 to +3 degrees from current temperature
        fallbackMin = currentTemp - 3;
        fallbackMax = currentTemp + 3;
        debugPrint('Fallback min/max calculated: $fallbackMin - $fallbackMax');
      }

      // Determine final min/max values to display
      final displayMin =
          calculatedTodayMin ?? currentWeather.tempMin?.celsius ?? fallbackMin;
      final displayMax =
          calculatedTodayMax ?? currentWeather.tempMax?.celsius ?? fallbackMax;

      debugPrint('Final display min: $displayMin, max: $displayMax');

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '📍${currentWeather.areaName ?? 'Unknown Location'}',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w300,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _getGreeting(),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 25,
              fontWeight: FontWeight.bold,
            ),
          ),
          Image.asset('assets/1.png'),
          Center(
            child: Text(
              '${currentWeather.temperature?.celsius?.round()}°C',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 55,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Center(
            child: Text(
              currentWeather.weatherMain?.toUpperCase() ?? 'UNKNOWN',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 25,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(height: 5),
          Center(
            child: Text(
              timeFormat.format(now),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w300,
              ),
            ),
          ),
          const SizedBox(height: 30),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Image.asset('assets/11.png', scale: 8),
                  const SizedBox(width: 5),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Sunrise',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w300,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        _formatTime(currentWeather.sunrise),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      )
                    ],
                  )
                ],
              ),
              Row(
                children: [
                  Image.asset('assets/12.png', scale: 8),
                  const SizedBox(width: 5),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Sunset',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w300,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        _formatTime(currentWeather.sunset),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      )
                    ],
                  )
                ],
              )
            ],
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 5.0),
            child: Divider(color: Colors.grey),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Image.asset('assets/13.png', scale: 8),
                  const SizedBox(width: 5),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Temp Max',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w300,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '${displayMax?.round()}°C',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      )
                    ],
                  )
                ],
              ),
              Row(
                children: [
                  Image.asset('assets/14.png', scale: 8),
                  const SizedBox(width: 5),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Temp Min',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w300,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '${displayMin?.round()}°C',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      )
                    ],
                  )
                ],
              )
            ],
          ),
        ],
      );
    }

    // Initial state
    return const Center(
      child: Text(
        'Welcome to AirHygro',
        style: TextStyle(color: Colors.white, fontSize: 24),
      ),
    );
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) {
      return 'Good Morning';
    } else if (hour < 17) {
      return 'Good Afternoon';
    } else {
      return 'Good Evening';
    }
  }

  String _formatTime(DateTime? time) {
    if (time == null) return '--:--';
    return DateFormat('h:mm a').format(time);
  }
}
