import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:weather_app/blocs/theme_bloc.dart';
import 'package:weather_app/blocs/weather_bloc.dart';
import 'package:weather_app/events/theme_event.dart';
import 'package:weather_app/events/weather_event.dart';
import 'package:weather_app/screens/city_search_screen.dart';
import 'package:weather_app/screens/settings_screen.dart';
import 'package:weather_app/screens/temperature_widget.dart';
import 'package:weather_app/states/theme_state.dart';
import 'package:weather_app/states/weather_state.dart';

class WeatherScreen extends StatefulWidget {
  @override
  _WeatherScreenState createState() => _WeatherScreenState();
}

class _WeatherScreenState extends State<WeatherScreen> {
  Completer<void> _completer;

  @override
  void initState() {
    super.initState();
    _completer = Completer<void>();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Weather App using Flutter Bloc'),
        actions: <Widget>[
          IconButton(
            icon: Icon(Icons.settings),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => SettingsScreen(),
                ),
              );
            },
          ),
          IconButton(
            icon: Icon(Icons.search),
            onPressed: () async {
              final typedCity = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => CitySearchScreen(),
                ),
              );
              if(typedCity !=null){
                BlocProvider.of<WeatherBloc>(context).add(
                  WeatherEventRequested(city: typedCity)
                );
              }
            },
          ),
        ],
      ),
      body: Center(
        child: BlocConsumer<WeatherBloc, WeatherState>(
          listener: (context, weatherState) {
            if (weatherState is WeatherStateSuccess) {
              BlocProvider.of<ThemeBloc>(context).add(
                ThemeEventWeatherChanged(
                    weatherCondition: weatherState.weather.weatherCondition),
              );
              _completer?.complete();
              _completer = Completer();
            }
          },
          builder: (context, weatherState) {
            if (weatherState is WeatherStateLoading) {
              return Center(
                child: CircularProgressIndicator(),
              );
            }
            if (weatherState is WeatherStateSuccess) {
              final weather = weatherState.weather;
              return BlocBuilder<ThemeBloc, ThemeState>(
                  builder: (context, themeSate) {
                return RefreshIndicator(
                  onRefresh: () {
                    BlocProvider.of<WeatherBloc>(context).add(
                      WeatherEventRefresh(city: weather.location),
                    );
                    return _completer.future;
                  },
                  child: Container(
                    color: themeSate.backgroundColor,
                    child: Padding(
                      padding: const EdgeInsets.only(top: 20.0),
                      child: ListView(
                        children:<Widget> [
                          Column(
                            children:<Widget> [
                              Text(
                                weather.location,
                                style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: themeSate.textColor),
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(vertical: 2),
                                child: Center(
                                  child: Text(
                                    'Update: ${TimeOfDay.fromDateTime(weather.lastUpdated).format(context)}',
                                    style: TextStyle(
                                        fontSize: 16, color: themeSate.textColor),
                                  ),
                                ),
                              ),
                              TemperatureWidget(weather: weather)
                            ],
                          )
                        ],
                      ),
                    ),
                  ),
                );
              });
            }
            if (weatherState is WeatherStateFailure) {
              return Text(
                'Something went wrong',
                style: TextStyle(color: Colors.redAccent, fontSize: 16),
              );
            }
            return Center(
              child: Text(
                'select a location first',
                style: TextStyle(fontSize: 30),
              ),
            );
          },
        ),
      ),
    );
  }
}
