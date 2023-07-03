import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => MyAppState(),
      child: MaterialApp(
        title: 'Random Word Generator',
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(seedColor: Color.fromRGBO(124, 157, 214, 1)),
        ),
        debugShowCheckedModeBanner: false,
        home: MyHomePage(),
      ),
    );
  }
}

class MyAppState extends ChangeNotifier {
  var current = 0;
  bool isFav = false;

  void getNext() {
    current++;
    isFav = false;
    notifyListeners();
  }

  List favorites = [];

  void toggleFavorite(images) {
    if (favorites.contains(images[current])) {
      favorites.remove(images[current]);
      isFav = false;
    } else {
      favorites.add(images[current]);
      isFav = true;
    }
    notifyListeners();
  }
}

// ...

class MyHomePage extends StatefulWidget {

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {

  var selectedIndex = 0;

  @override
  Widget build(BuildContext context) {

    Widget page;

    switch (selectedIndex) {
      case 0: 
        page = GeneratorPage();
        break;
      case 1:
        page = FavoritesPage();
        break;
      default: 
        throw UnimplementedError('no widget for $selectedIndex');
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        return Scaffold(
          body: Row(
            children: [
              SafeArea(
                child: NavigationRail(
                  extended: constraints.maxWidth >= 600,
                  destinations: [
                    NavigationRailDestination(
                      icon: Icon(Icons.home),
                      label: Text('Home'),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.favorite),
                      label: Text('Favorites'),
                    ),
                  ],
                  selectedIndex: selectedIndex,
                  onDestinationSelected: (value) {
                    setState(() {
                      selectedIndex = value;
                    });
                  },
                ),
              ),
              Expanded(
                child: Container(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  child: page,
                ),
              ),
            ],
          ),
        );
      }
    );
  }
}


class GeneratorPage extends StatefulWidget {
  @override
  State<GeneratorPage> createState() => _GeneratorPageState();
}

class _GeneratorPageState extends State<GeneratorPage> {

  @override
  void initState() {
    super.initState();
  }

  Future<List> fetchPhoto() async {
    final res = await http.get(Uri.parse('https://api.pexels.com/v1/search?query=animals&orientation=landscape&size=medium'),
      headers: {
        'Authorization': '9AEW491uobXRZwMqGTxuo0hdRavXmB2zdxv6bLDyKb0QzmB5GxnjaHnU'
    });
    
    if (res.statusCode == 200) {
      Map result = jsonDecode(res.body);
      // final state = Provider.of<MyAppState>(context, listen: false);
      // final state = context.read<MyAppState>();
      // setState(() {
      //   images = result['photos'];
      // });
      // state.addImages(result['photos']);
      List<dynamic> images = result['photos'];
      return images;
    } else {
      throw Exception('failed to laod');
    }
  }

  @override
  Widget build(BuildContext context) {
    var appState = context.watch<MyAppState>();
    var current = appState.current;
    final isFav = appState.isFav;

    return FutureBuilder(
      future: fetchPhoto(),
      builder: (context, AsyncSnapshot<List<dynamic>> snapshot) {
        if (snapshot.hasData) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                BigCard(images: snapshot.data!, index: current),
                SizedBox(height: 10),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ElevatedButton.icon(
                      icon: Icon(
                        isFav ? Icons.favorite : Icons.favorite_border,
                      ),
                      onPressed: () {
                        appState.toggleFavorite(snapshot.data!);
                      },
                      label: Text('Like'),
                    ),
                    SizedBox(width: 10),
                    ElevatedButton(
                      onPressed: () {
                        appState.getNext();
                      },
                      child: Text('Next'),
                    ),
                  ],
                ),
              ],
            ),
          );
        } else if (snapshot.hasError){
          return Text('something went wrong');
        } else {
          return CircularProgressIndicator();
        }
      }
    );
  }
}

// ...

class FavoritesPage extends StatelessWidget {
  
  @override
  Widget build(BuildContext context) {
    var appState = context.watch<MyAppState>();
    var favorites = appState.favorites;

    if (favorites.isEmpty) {
      return Center(
        child: Text('No favorites yet.'),
      );
    }

    return ListView(
      children: [
        Padding(
          padding: const EdgeInsets.all(20),
          child: Text('You have '
              '${favorites.length} favorites:'),
        ),
        for (var image in favorites)
        Padding(
          padding: const EdgeInsets.symmetric(
            vertical: 10,
            horizontal: 0,
          ),
          child: Image.network(image['src']['medium'])
        )
      ],
    );
  }
}

class BigCard extends StatelessWidget {
  const BigCard({
    super.key,
    required this.images,
    required this.index,
  });

  final List images;
  final int index;

  @override
  Widget build(BuildContext context) {

    return Card(
      color: Color.fromRGBO(191, 215, 255, 1),
      
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Image.network(images[index]['src']['medium'])
      ),
    );
  }
}