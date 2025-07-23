import 'package:airhygro/bloc/weather_bloc.dart';
import 'package:airhygro/screens/home_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';


void main() {
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: BlocProvider<WeatherBloc>(
        create: (context) => WeatherBloc()..add(FetchWeather()),
        child: const HomeScreen(),
      ),
    );
  }
}